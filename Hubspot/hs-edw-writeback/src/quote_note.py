from src.logger import get_logger
import src.timetracking as timetracking
import constants
import pyodbc
import requests
import json
import re
import uuid
from collections import Counter

logger = get_logger(__name__)


class QuoteNote:

    def sync_to_edw(timestamp_start):
        logger.info('quote note sync started')

        # 1) Fetch the quote notes
        quote_notes = QuoteNote.get_all_notes_modified_after_timestamp(timestamp_start)
        all_notes = quote_notes.get('results', [])
        total_notes = len(all_notes)
        logger.info(f'Total quote notes retrieved from HubSpot: {total_notes}')

        # 2) Initialize counters
        inserted_count = 0
        skipped_no_policy = 0
        error_count = 0
        skip_no_deals = 0

        # Track how many notes had each distinct "from_metal" value
        from_metal_counter = Counter()

        # 3) Process each note
        for row in all_notes:
            # Count from_metal property value
            from_metal_val = row['properties'].get('from_metal')
            from_metal_counter[from_metal_val] += 1

            formatted_body = QuoteNote.strip_html_tags(row['properties']['hs_note_body'])
            row['properties']['hs_note_body'] = formatted_body
            note_id = row['id']

            related_deal_ids = QuoteNote.get_related_deal_ids(note_id)
            if not related_deal_ids:
                logger.warning(f"No deals found for note_id: {note_id}. Skipping.")
                skip_no_deals += 1
                continue

            for deal_id in related_deal_ids:
                policy_number_list = QuoteNote.get_related_deal_quote_no(deal_id)

                if not policy_number_list:
                    logger.warning(f"No policy number found for deal_id: {deal_id}, skipping note id: {note_id}")
                    skipped_no_policy += 1
                    continue

                policy_number = policy_number_list[0]

                try:
                    hubspot_owner_id = row['properties'].get('hubspot_owner_id')
                    if hubspot_owner_id is None:
                        hubspot_owner_id = 'Unknown'

                    # Debug info logs
                    logger.info("from_metal " + str(from_metal_val))
                    logger.info(f"Processing HubSpot note row: {json.dumps(row, indent=2)}")

                    payload = {
                        'hs_note_id': row['properties']['hs_object_id'],
                        'hs_note_body': row['properties']['hs_note_body'],
                        'note_id': str(uuid.uuid4()),
                        'quote_no': policy_number,
                        'created_by': hubspot_owner_id,
                        'create_ts': row['properties']['hs_createdate'],
                        'update_ts': row['properties']['hs_lastmodifieddate'],
                    }

                    logger.info(f"Final payload to insert: {payload}")

                    # Parameterized SQL statement
                    sql = """
                    SET NOCOUNT ON;
                    INSERT INTO edw_stage.hubspot_quote_notes (
                        hs_note_id,
                        hs_note_body,
                        note_id,
                        quote_no,
                        created_by,
                        create_ts,
                        update_ts
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """

                    params = [
                        payload['hs_note_id'],
                        payload['hs_note_body'],
                        payload['note_id'],
                        payload['quote_no'],
                        payload['created_by'],
                        payload['create_ts'],
                        payload['update_ts']
                    ]

                    # Insert record
                    QuoteNote.insert_data_into_table(sql, params)
                    logger.info(f'quote note successfully created in edw: {row}')
                    inserted_count += 1

                except Exception as e:
                    logger.error(f'error while inserting quote note into edw (note_id {note_id}): {e}', exc_info=True)
                    error_count += 1

        # 4) Final summary
        logger.info("Quote Note Sync Summary:")
        logger.info(f"  - Total notes retrieved: {total_notes}")
        logger.info(f"  - Inserted successfully: {inserted_count}")
        logger.info(f"  - Skipped (no deals):    {skip_no_deals}")
        logger.info(f"  - Skipped (no policy):  {skipped_no_policy}")
        logger.info(f"  - Errors during insert: {error_count}")

        # 5) Log how many notes had each distinct from_metal value
        logger.info("from_metal property distribution:")
        for key, count in from_metal_counter.items():
            logger.info(f"  * {key}: {count}")

    @staticmethod
    def get_all_notes_modified_after_timestamp(timestamp_start):
        unix_start = timetracking.format_unix_timestamp(timestamp_start)
        endpoint = 'crm/v3/objects/notes/search'
        url = f"{constants.hubapi}/{endpoint}"

        all_results = []
        after = None  # pagination token

        while True:
            data = {
                'limit': 200,
                'properties': [
                    'id',
                    'hs_note_body',
                    'policy_number',
                    'hubspot_owner_id',
                    'from_metal',
                ],
                'filterGroups': [
                    {
                        'filters': [
                            {
                                'propertyName': 'hs_lastmodifieddate',
                                'value': str(unix_start),
                                'operator': 'GT',
                            },
                            {
                                'propertyName': 'from_metal',
                                'value': 'true',
                                'operator': 'NEQ',
                            },
                        ],
                    },
                ]
            }

            if after:
                data['after'] = after

            try:
                response = requests.post(
                    url=url,
                    headers=constants.hs_headers,
                    data=json.dumps(data)
                )

                if response.ok:
                    json_response = response.json()
                    results = json_response.get('results', [])
                    all_results.extend(results)

                    paging = json_response.get('paging')
                    if paging and 'next' in paging and 'after' in paging['next']:
                        after = paging['next']['after']
                        logger.info(f"Fetching next page with after={after}")
                    else:
                        break  # No more pages
                else:
                    logger.error(f"API error: {response.status_code} - {response.text}")
                    break

            except Exception as e:
                logger.error(f'Error fetching quote notes: {e}')
                break

        return {'results': all_results}

    @staticmethod
    def get_related_deal_ids(note_id):
        try:
            endpoint = f'crm/v4/objects/notes/{note_id}/associations/deals'
            url = f'{constants.hubapi}/{endpoint}'
            response = requests.get(url=url, headers=constants.hs_headers).json()
            results = response['results'] if 'results' in response else []
            id_list = []

            for id in results:
                id_list.append(id['toObjectId'])
                logger.info(f'deal id successfully retrieved: {id} for hubspot note id: {note_id}')
            return id_list

        except Exception as e:
            logger.error(f'error while getting hubspot deal id related to quote note: {e}')
            return []

    @staticmethod
    def get_related_deal_quote_no(deal_id):
        try:
            endpoint = f'crm/v3/objects/deals/search'
            url = f"{constants.hubapi}/{endpoint}"
            data = {
                'properties': [
                    'id',
                    'policy_number',
                ],
                'filterGroups': [
                    {
                        'filters': [
                            {
                                'propertyName': 'hs_object_id',
                                'value': f'{deal_id}',
                                'operator': 'EQ',
                            },
                        ],
                    },
                ],
            }
            data = json.dumps(data)
            response = requests.post(url=url, headers=constants.hs_headers, data=data).json()
            results = response['results'] if 'results' in response else []
            policy_no_list = []

            for id in results:
                policy_no = id['properties']['policy_number']
                policy_no_list.append(policy_no)
                logger.info(f'hubspot deal id successfully retrieved: {id} for quote: {policy_no}')
            return policy_no_list

        except Exception as e:
            logger.error(f'error while getting quote no. of related quote: {e}')
            return []

    @staticmethod
    def strip_html_tags(text):
        if text is None:
            return ''
        try:
            if not isinstance(text, (str, bytes)):
                logger.error(f'function error: strip_html_tags - invalid input type (expected str or bytes, received {type(text)})')
                raise ValueError(f"invalid input type: {type(text)}. Expected str or bytes.")

            clean = re.compile('<.*?>')
            return re.sub(clean, '', text)

        except Exception as e:
            logger.error(f'error while stripping html tags from quote note body: {e}')
            return ''

    @staticmethod
    def insert_data_into_table(sql_query, params):
        try:
            conn = pyodbc.connect(constants.connection_string)
            cursor = conn.cursor()
            cursor.execute(sql_query, params)
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f'error while inserting quote note record into edw: {e}')
