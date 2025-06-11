from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
from shared.logger import get_logger
import shared.hubspot as hubspot

import sqlite3

logger = get_logger(__name__)



class Customer:

    def sync_to_hubspot():
        customer_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['customer'])
        
        if not customer_df.empty:
            # 1. ALERT: Check for and log any duplicates before taking action.
            check_and_log_duplicates(customer_df, 'customer_id', 'Customer')

            # 2. deduplicate on customer id since customer table has a line item per policy, but only data from 1 line item is needed
            customer_df.drop_duplicates(subset='customer_id', keep='first', inplace=True, ignore_index=True )
            create_batch_payload = {"inputs": []}  
            update_batch_payload = {"inputs": []}  

            for index, row in customer_df.iterrows(): 
                try:
                    hs_object_id = Customer.return_customer_hs_id_for_update(row['customer_id'])

                    if hs_object_id:
                        row['hs_object_id'] = hs_object_id
                        record_payload = Customer.build_payload(row, update=True)
                        update_batch_payload['inputs'].append(record_payload)                                             
                    else:
                        record_payload = Customer.build_payload(row, update=False)
                        create_batch_payload['inputs'].append(record_payload)

                except Exception as e:
                    logger.error(f'error while processing data: {e}')
                    continue
                
            update_records = hubspot.UpdateRecordsHandler('contacts', 'customer_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler('contacts', 'customer_create')
            create_records.dispatch(create_batch_payload)


    def return_customer_hs_id_for_update(customer_id):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_contact_id FROM customer WHERE customer_id = '{customer_id}'
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
                'type': 'Customer',
                'customer_id': record['customer_id'],
                'broker_id': record['broker_id'],
                'firstname': record['first_nm'],
                'lastname': record['last_nm'],
                'email': record['email'],
                #'product_name': record['product_nm'],
                'bdm_name': record['bdm_nm'],
                # 'broker_name': record['broker_nm'],
                # 'broker_phone_no': record['broker_phone_no'],
                # 'producer_name': record['producer_nm'],
                'mailing_address_line_1': record['mailing_address_line_1'],
                'mailing_address_line_2': record['mailing_address_line_2'],
                'mailing_address_unit_no': record['mailing_address_unit_no'],
                'mailing_address_city_nm': record['mailing_address_city_nm'],               
                'mailing_address_zip_cd': record['mailing_address_zip_cd'],
                'risk_state_cd': record['risk_state_cd'],
                'mailing_address_state_cd': record['mailing_address_state_cd']

                #'policy_status': record['policy_status'],
                # 'create_ts': record['create_ts'],
                # 'update_ts': record['update_ts'],
                # 'etl_audit_sk': record['etl_audit_sk'],
                }
            }
        
        if update:
            payload['id'] = record['hs_object_id']

        return payload


    def associate_records():
        Customer.customer_broker_associations()
        Customer.customer_quote_associations()
        Customer.customer_policy_associations()

    
    def customer_broker_associations():
        customer_broker_associations_df = Association.get_associations(table1='customer', id1='hs_contact_id', table2='broker', id2='hs_company_id', key_column='broker_id')
        customer_broker_association_payload = {"inputs": []}
 
        for index, row in customer_broker_associations_df.iterrows():
            from_id = row['hs_contact_id']
            to_id = row['hs_company_id']
            association_type_id = Association.association_type_id['customer-broker']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            customer_broker_association_payload['inputs'].append(record_payload)

        customer_broker_associations = hubspot.AssociationHandler('customer-broker-association', 'customer-broker-associations')
        customer_broker_associations.dispatch(customer_broker_association_payload)


    def customer_quote_associations():
        customer_quote_associations_df = Association.get_associations(table1='customer', id1='hs_contact_id', table2='quote', id2='hs_object_id', key_column='customer_id')
        customer_quote_association_payload = {"inputs": []}

        for index, row in customer_quote_associations_df.iterrows():
            from_id = row['hs_object_id']
            to_id = row['hs_contact_id']
            association_type_id = Association.association_type_id['customer-quote']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            customer_quote_association_payload['inputs'].append(record_payload)
        
        customer_quote_associations = hubspot.AssociationHandler('customer-quote-association', 'customer-quote-associations')
        customer_quote_associations.dispatch(customer_quote_association_payload)


    def customer_policy_associations():
        customer_policy_associations_df = Association.get_associations(table1='customer', id1='hs_contact_id', table2='policy', id2='hs_object_id', key_column='customer_id')
        customer_policy_association_payload = {"inputs": []}

        for index, row in customer_policy_associations_df.iterrows():
            from_id = row['hs_contact_id']
            to_id = row['hs_object_id']
            association_type_id = Association.association_type_id['customer-policy']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            customer_policy_association_payload['inputs'].append(record_payload)
        
        customer_quote_associations = hubspot.AssociationHandler('customer-policy-association', 'customer-policy-associations')
        customer_quote_associations.dispatch(customer_policy_association_payload)


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