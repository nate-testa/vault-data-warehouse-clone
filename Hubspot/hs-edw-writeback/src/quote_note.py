from src.logger import get_logger
import src.timetracking as timetracking
import constants


import pyodbc
import requests
import json 
import re
import uuid


logger = get_logger(__name__)



class QuoteNote:

    def sync_to_edw(timestamp_start):
        logger.info('quote note sync started')
        quote_notes = QuoteNote.get_all_notes_modified_after_timestamp(timestamp_start)
    
        for row in quote_notes['results']:
            formatted_body = QuoteNote.strip_html_tags(row['properties']['hs_note_body'])
            row['properties']['hs_note_body'] = formatted_body 
            note_id = row['id']
            related_deal_ids = QuoteNote.get_related_deal_ids(note_id)

            for deal_id in related_deal_ids:
                policy_number = QuoteNote.get_related_deal_quote_no(deal_id)[0]

                try:
                    payload = {
                        'hs_note_id': row['properties']['hs_object_id'],
                        'hs_note_body': row['properties']['hs_note_body'],
                        'note_id': f'{uuid.uuid4()}',
                        'quote_no': policy_number,
                        'created_by': row['properties']['hubspot_owner_id'],
                        'create_ts': row['properties']['hs_createdate'],
                        'update_ts': row['properties']['hs_lastmodifieddate'],  
                    }
                    sql = f'''
                    SET NOCOUNT ON
                    INSERT INTO edw_stage.hubspot_quote_notes (hs_note_id, hs_note_body, note_id, quote_no, created_by, create_ts, update_ts)
                    VALUES ('{payload['hs_note_id']}', '{payload['hs_note_body']}', '{payload['note_id']}', '{payload['quote_no']}', '{payload['created_by']}', '{payload['create_ts']}', '{payload['update_ts']}')
                    '''
                    QuoteNote.insert_data_into_table(sql)
                    logger.info(f'quote note successfully created in edw: {row}')

                except Exception as e:
                    logger.error(f'error while inserting quote note into edw: {e}')


    def get_all_notes_modified_after_timestamp(timestamp_start):
        unix_start = timetracking.format_unix_timestamp(timestamp_start)
        endpoint = f'crm/v3/objects/notes/search'
        url = f"{constants.hubapi}/{endpoint}"
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
                            'value': f'{unix_start}',
                            'operator': 'GT',
                        },

                        {
                            'propertyName': 'from_metal',
                            'value': 'true',
                            'operator': 'NEQ',
                        },
                    ],
                },
            ],
            }
        data = json.dumps(data)
        try:
            response = requests.post(url=url, headers=constants.hs_headers, data=data)
        except Exception as e:
            logger.error(f'with function error requesting all quote notes modified since last run: {e}')
        
        if response and response.ok:
            results = response.json()
            return results

        else:
            logger.error(f'api error with function to get all quote notes modified after last run time: {response.status_code}')
            logger.error(response.text)
        



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


    def insert_data_into_table(sql_query):
        try:
            conn = pyodbc.connect(constants.connection_string)
            cursor = conn.cursor()
            cursor.execute(sql_query)
            conn.commit()
            conn.close()

        except Exception as e:
            logger.error(f'error while inserting quote note record into edw: {e}')