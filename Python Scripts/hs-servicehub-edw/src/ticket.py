from src.logger import get_logger
import src.timetracking as timetracking
import constants

from datetime import datetime
import pyodbc
import requests
import json
import time


logger = get_logger(__name__)


class Ticket:

    @staticmethod
    def sync_to_edw(start_time, end_time):
        logger.info(f'ticket sync started — range: {start_time} to {end_time}')

        all_tickets = Ticket.search_tickets(start_time, end_time)
        logger.info(f'fetched {len(all_tickets)} tickets from HubSpot')

        inserted = 0
        failed = 0

        for ticket in all_tickets:
            try:
                payload = Ticket.build_edw_payload(ticket)
                Ticket.insert_into_edw(payload)
                inserted += 1
            except Exception as e:
                failed += 1
                logger.error(f'error inserting ticket {ticket.get("id")}: {e}')

        logger.info(f'ticket sync complete: {inserted} inserted, {failed} failed')

    @staticmethod
    def search_tickets(start_time, end_time):
        start_unix = timetracking.format_unix_timestamp(start_time)
        end_unix = timetracking.format_unix_timestamp(end_time)

        url = f'{constants.hubapi}/crm/v3/objects/tickets/search'
        all_results = []
        after = None

        while True:
            query = {
                'limit': 100,
                'properties': constants.ticket_properties,
                'filterGroups': [
                    {
                        'filters': [
                            {
                                'propertyName': 'hs_lastmodifieddate',
                                'value': str(start_unix),
                                'operator': 'GT',
                            },
                            {
                                'propertyName': 'hs_lastmodifieddate',
                                'value': str(end_unix),
                                'operator': 'LTE',
                            },
                        ],
                    },
                    {
                        'filters': [
                            {
                                'propertyName': 'createdate',
                                'value': str(start_unix),
                                'operator': 'GT',
                            },
                            {
                                'propertyName': 'createdate',
                                'value': str(end_unix),
                                'operator': 'LTE',
                            },
                        ],
                    },
                ],
            }

            if after:
                query['after'] = after

            response = requests.post(url=url, headers=constants.hs_headers, data=json.dumps(query))

            if not response.ok:
                logger.error(f'HubSpot API error {response.status_code}: {response.text}')
                break

            body = response.json()
            batch = body.get('results', [])
            all_results.extend(batch)
            logger.info(f'fetched batch of {len(batch)} tickets (total so far: {len(all_results)})')

            next_after = body.get('paging', {}).get('next', {}).get('after')
            if not next_after:
                break

            after = next_after
            time.sleep(0.3)

        return all_results

    @staticmethod
    def build_edw_payload(ticket):
        """Build EDW payload dynamically from constants.ticket_properties.
        Maps HubSpot API property names to EDW column names."""
        props = ticket.get('properties', {})
        payload = {}
        for field in constants.ticket_properties:
            edw_col = constants.ticket_column_map.get(field, field)
            payload[edw_col] = props.get(field)
        payload['create_ts'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        return payload

    @staticmethod
    def insert_into_edw(payload):
        columns = list(payload.keys())
        placeholders = ', '.join(['?' for _ in columns])
        col_names = ', '.join(columns)
        values = tuple(payload.values())

        sql = f'''
            SET NOCOUNT ON
            INSERT INTO {constants.ticket_table} ({col_names})
            VALUES ({placeholders})
        '''

        conn = pyodbc.connect(constants.connection_string)
        try:
            cursor = conn.cursor()
            cursor.execute(sql, values)
            conn.commit()
        except Exception:
            logger.exception(f'failed to insert ticket {payload.get("hs_object_id")} into EDW')
            raise
        finally:
            conn.close()
