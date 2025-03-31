from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.logger import get_logger
from objects.quote import Quote
import shared.hubspot as hubspot

import pandas as pd
import json
import sqlite3


logger = get_logger(__name__)



class QuoteNote:

    def sync_to_hubspot():
        quote_note_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['quote_note'])

        if not quote_note_df.empty:
            results = quote_note_df.apply(QuoteNote.process_row, axis=1)
            create_batch_payload = {"inputs": []}
            update_batch_payload = {"inputs": []}

            for action, payload in results:
                try:
                    if action == 'update':
                        update_batch_payload['inputs'].append(payload)
                    else:
                        create_batch_payload['inputs'].append(payload)

                except Exception as e:
                    logger.error(f'error while processing data: {e}')

            update_records = hubspot.UpdateRecordsHandler('notes', 'quote_note_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler('notes', 'quote_note_create')
            create_records.dispatch(create_batch_payload)


    def process_row(row):
        associated_deal_id = Quote.return_quote_hs_id_for_update(row['quote_no'])
        row['associated_deal_id'] = associated_deal_id
        row['note_desc'] = json.dumps(DatabaseFunctions.strip_html_tags(row['note_desc']))

        hs_object_id = QuoteNote.return_quote_note_hs_id_for_update(row['quote_no'])

        if hs_object_id:
            row['hs_object_id'] = hs_object_id
            record_payload = QuoteNote.build_payload(row, update=True)
            return 'update', record_payload
        else:
            record_payload = QuoteNote.build_payload(row, update=False)
            return 'create', record_payload    


    def return_quote_note_hs_id_for_update(quote_no):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_note_id FROM quote_note WHERE quote_no = '{quote_no}'
        '''
        query = cursor.execute(sql)
        result = query.fetchall()
        conn.close()

        if result:
            return result[0][0]
        else:
            return '' 
        

    def build_payload(record, update):
        formatted_unix_timestamp = pd.Timestamp(record['note_created_ts']) 
        record['hs_timestamp'] = formatted_unix_timestamp.value // 10**6

        payload = {
            'associations': [
                {
                    'types': [
                        {
                            'associationCategory': 'HUBSPOT_DEFINED',
                            'associationTypeId': 214,
                        },
                    ],
                    'to': {
                        'id': f"{record['associated_deal_id']}",
                    }
                }
            ],

            'properties': {
                'hs_note_body': record['note_desc'],
                'hs_timestamp': record['hs_timestamp'],
                'quote_no': record['quote_no'],
                'from_metal': True           
            }
        }
        if update:
            payload['id'] = record['hs_object_id']
        
        return payload
        


        


          

