from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
from shared.logger import get_logger
import shared.hubspot as hubspot

import sqlite3

logger = get_logger(__name__)



class Producer:

    def sync_to_hubspot():
        producer_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['producer'])

        if not producer_df.empty:
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
    
          