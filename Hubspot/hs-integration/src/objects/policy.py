from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
import shared.hubspot as hubspot
from shared.logger import get_logger
import constants

import sqlite3

logger = get_logger(__name__)

class Policy:

    def sync_to_hubspot():
        policy_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['policy'])

        if not policy_df.empty:
            results = policy_df.apply(Policy.process_row, axis=1)
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
        
            update_records = hubspot.UpdateRecordsHandler(constants.policy_object_id, 'policy_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler(constants.policy_object_id, 'policy_create')
            create_records.dispatch(create_batch_payload)
    
    
    def process_row(row):
        hs_object_id = Policy.return_policy_hs_id_for_update(row['policy_no'])

        if hs_object_id:
            row['hs_object_id'] = hs_object_id
            record_payload = Policy.build_payload(row, update=True)
            return 'update', record_payload
        else:
            record_payload = Policy.build_payload(row, update=False)
            return 'create', record_payload


    def return_policy_hs_id_for_update(policy_no):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_object_id FROM policy WHERE policy_no = '{policy_no}'
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
                'policy_name': record['policy_no'],
                'customer_id': record['customer_id'],
                'broker_id': record['broker_id'],
                'firstname': record['first_nm'],
                'lastname': record['last_nm'],
                'email': record['email'],
                'product_name': record['product_nm'],
                'bdm_nm': record['bdm_nm'],
                'broker_name': record['broker_nm'],
                'broker_phone_no': record['broker_phone_no'],
                # 'producer_name': record['producer_nm'],
                'mailing_address_line_1': record['mailing_address_line_1'],
                'mailing_address_line_2': record['mailing_address_line_2'],
                'mailing_address_unit_no': record['mailing_address_unit_no'],
                'mailing_address_city_nm': record['mailing_address_city_nm'],               
                'mailing_address_zip_cd': record['mailing_address_zip_cd'],
                'mailing_address_state_cd': record['mailing_address_state_cd'],
                'risk_address_line_1': record['mailing_address_line_1'],
                'risk_address_line_2': record['mailing_address_line_2'],
                'risk_address_unit_no': record['mailing_address_unit_no'],
                'risk_address_city_nm': record['mailing_address_city_nm'],
                'risk_state_cd': record['risk_state_cd'],               
                'risk_address_zip_cd': record['mailing_address_zip_cd'],
                'policy_status': record['policy_status'],
                'monoline_in': record['monoline_in']
                
                # 'create_ts': record['create_ts'],
                # 'update_ts': record['update_ts'],
                # 'etl_audit_sk': record['etl_audit_sk'],
                }
            }
        if update:
            payload['id'] = record['hs_object_id']

        return payload
    

    def associate_records():
        policy_customer_associations_df = Association.get_associations(table1='policy', id1='hs_object_id', table2='customer', id2='hs_contact_id', key_column='customer_id')
        policy_customer_associations_payload = {"inputs": []}
 
        for index, row in policy_customer_associations_df.iterrows():
            from_id = row['hs_contact_id']
            to_id = row['hs_object_id']
            association_type_id = Association.association_type_id['customer-policy']
            record_payload = Association.build_association_payload(from_id=from_id, to_id=to_id, association_type_id=association_type_id)
            policy_customer_associations_payload['inputs'].append(record_payload)

        policy_customer_associations = hubspot.AssociationHandler('customer-policy-association', 'customer-policy-associations')
        policy_customer_associations.dispatch(policy_customer_associations_payload)


        policy_broker_associations_df = Association.get_associations(table1='policy', id1='hs_object_id', table2='broker', id2='hs_company_id', key_column='broker_id')
        policy_broker_associations_payload = {"inputs": []}
 
        for index, row in policy_broker_associations_df.iterrows():
            from_id = row['hs_company_id']
            to_id = row['hs_object_id']
            association_type_id = Association.association_type_id['broker-policy']
            record_payload = Association.build_association_payload(from_id=from_id, to_id=to_id, association_type_id=association_type_id)
            policy_broker_associations_payload['inputs'].append(record_payload)

        policy_broker_associations = hubspot.AssociationHandler('broker-policy-association', 'broker-policy-associations')
        policy_broker_associations.dispatch(policy_broker_associations_payload)

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