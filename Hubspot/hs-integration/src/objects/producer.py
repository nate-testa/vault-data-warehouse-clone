from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
from shared.logger import get_logger
import shared.hubspot as hubspot

import sqlite3

logger = get_logger(__name__)

def check_and_log_duplicates(df, id_column, object_name):
    """
    Checks a DataFrame for duplicates based on an ID column and logs a warning if any are found.

    Args:
        df (pd.DataFrame): The DataFrame to check.
        id_column (str): The name of the column to check for duplicates (e.g., 'producer_id').
        object_name (str): The name of the object for the log message (e.g., 'Producer').
    """
    # Find all rows that are part of a set of duplicates
    duplicates = df[df.duplicated(subset=id_column, keep=False)]

    if not duplicates.empty:
        # Get a list of the unique IDs that have duplicate entries
        duplicated_ids = duplicates[id_column].unique()
        logger.warning(
            f"Found {len(duplicated_ids)} {object_name} ID(s) with duplicate records in the source data. "
            f"These duplicates will be dropped before processing. "
            f"Duplicated IDs: {list(duplicated_ids)}"
        )

class Producer:

    def sync_to_hubspot():
        producer_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['producer'])

        if not producer_df.empty:
            # 1. ALERT: Check for and log any duplicates before taking action.
            check_and_log_duplicates(producer_df, 'producer_id', 'Producer')

            # 2. Deduplicate on producer_id to ensure each producer is processed only once
            producer_df.drop_duplicates(subset='producer_id', keep='first', inplace=True, ignore_index=True)

            results = producer_df.apply(Producer.process_row, axis=1)
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

            update_records = hubspot.UpdateRecordsHandler('contacts', 'producer_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler('contacts', 'producer_create')
            create_records.dispatch(create_batch_payload)
    
    
    def process_row(row):
        hs_object_id = Producer.return_producer_hs_id_for_update(row['producer_id'])

        if hs_object_id:
            row['hs_object_id'] = hs_object_id
            record_payload = Producer.build_payload(row, update=True)
            return 'update', record_payload
        else:
            record_payload = Producer.build_payload(row, update=False)
            return 'create', record_payload
            

    def return_producer_hs_id_for_update(producer_id):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_contact_id FROM producer WHERE producer_id = '{producer_id}'
        '''
        query = cursor.execute(sql)
        result = query.fetchall()
        conn.close()

        if result:
            return result[0][0]
        else:
            return None   


    def build_payload(record, update):
        payload = {
            'properties': {
                'type': 'Agency',
                'broker_id': record['broker_id'],
                'producer_id': record['producer_id'],
                'email': record['email'],
                'firstname': record['first_nm'],
                'lastname': record['last_nm'],
                'phone': record['phone_no'],
                'jobtitle': record['title'],
                'role': record['producer_role'],
                'producer_status': record['producer_status']

                # 'agency_status': record['broker_status'],                
                # 'create_ts': record['create_ts'],
                # 'update_ts': record['update_ts'],
                # 'etl_audit_sk': record['etl_audit_sk']
            }
        } 

        if update:
            payload['id'] = record['hs_object_id']
        
        return payload
        

    def associate_records():
        Producer.producer_broker_associations()


    def producer_broker_associations():
        producer_broker_associations_df = Association.get_associations(table1='producer', id1='hs_contact_id', table2='broker', id2='hs_company_id', key_column='broker_id')
        producer_broker_association_payload = {"inputs": []}
 
        for index, row in producer_broker_associations_df.iterrows():
            from_id = row['hs_contact_id']
            to_id = row['hs_company_id']
            association_type_id = Association.association_type_id['producer-broker']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            producer_broker_association_payload['inputs'].append(record_payload)

        customer_associations = hubspot.AssociationHandler('producer-broker-association', 'producer-associations')
        customer_associations.dispatch(producer_broker_association_payload)    
