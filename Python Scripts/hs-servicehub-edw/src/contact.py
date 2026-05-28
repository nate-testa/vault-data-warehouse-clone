from src.logger import get_logger
import src.timetracking as timetracking
import constants

from datetime import datetime
import pyodbc
import requests
import json
import time


logger = get_logger(__name__)


class Contact:

    @staticmethod
    def sync_to_edw(start_time, end_time):
        logger.info(f'contact sync started — range: {start_time} to {end_time}')

        all_contacts = Contact.search_contacts(start_time, end_time)
        logger.info(f'fetched {len(all_contacts)} contacts from HubSpot')

        inserted = 0
        failed = 0

        for contact in all_contacts:
            try:
                payload = Contact.build_edw_payload(contact)
                Contact.insert_into_edw(payload)
                inserted += 1
            except Exception as e:
                failed += 1
                logger.error(f'error inserting contact {contact.get("id")}: {e}')

        logger.info(f'contact sync complete: {inserted} inserted, {failed} failed')

    @staticmethod
    def search_contacts(start_time, end_time):
        start_unix = timetracking.format_unix_timestamp(start_time)
        end_unix = timetracking.format_unix_timestamp(end_time)

        url = f'{constants.hubapi}/crm/v3/objects/contacts/search'
        all_results = []
        after = None

        while True:
            query = {
                'limit': 100,
                'properties': constants.contact_properties,
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
            logger.info(f'fetched batch of {len(batch)} contacts (total so far: {len(all_results)})')

            next_after = body.get('paging', {}).get('next', {}).get('after')
            if not next_after:
                break

            after = next_after
            time.sleep(0.3)

        return all_results

    @staticmethod
    def build_edw_payload(contact):
        """Build EDW payload dynamically from constants.contact_properties.
        Maps HubSpot API property names to EDW column names."""
        props = contact.get('properties', {})
        payload = {}
        for field in constants.contact_properties:
            edw_col = constants.contact_column_map.get(field, field)
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
            INSERT INTO {constants.contact_table} ({col_names})
            VALUES ({placeholders})
        '''

        conn = pyodbc.connect(constants.connection_string)
        try:
            cursor = conn.cursor()
            cursor.execute(sql, values)
            conn.commit()
        except Exception:
            logger.exception(f'failed to insert contact {payload.get("hs_object_id")} into EDW')
            raise
        finally:
            conn.close()
