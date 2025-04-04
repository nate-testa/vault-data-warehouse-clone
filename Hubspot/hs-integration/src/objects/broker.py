from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
from shared.logger import get_logger
import shared.hubspot as hubspot

import sqlite3

logger = get_logger(__name__)



class Broker:

    def sync_to_hubspot():
        broker_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['broker'])
        
        if not broker_df.empty:
            results = broker_df.apply(Broker.process_row, axis=1)
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
                    continue

            update_records = hubspot.UpdateRecordsHandler('companies', 'broker_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler('companies', 'broker_create')
            create_records.dispatch(create_batch_payload)
    
    
    def process_row(row):
        hs_object_id = Broker.return_broker_hs_id_for_update(row['broker_id'])

        if hs_object_id:
            row['hs_object_id'] = hs_object_id
            record_payload = Broker.build_payload(row, update=True)
            return 'update', record_payload
        else:
            record_payload = Broker.build_payload(row, update=False)
            return 'create', record_payload

    
    def return_broker_hs_id_for_update(broker_id):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_company_id FROM broker WHERE broker_id = '{broker_id}'
        '''
        query = cursor.execute(sql)
        result = query.fetchall()
        conn.close()

        if result:
            return result[0][0]
        else:
            return None    


    def build_payload(record, update):
        
        if record['broker_tier'] == '0.0':
            record['broker_tier'] = 0
        elif record['broker_tier'] is None or record['broker_tier'] == '':
            record['broker_tier'] = ''
        else:
            record['broker_tier'] = int(record['broker_tier'])

        payload = {
            'properties': {
                'broker_id': record['broker_id'],
                'name': record['broker_nm'],
                'mailing_address_line_1': record['mailing_address_line_1'],
                'mailing_address_line_2': record['mailing_address_line_2'],
                'mailing_address_city_nm': record['mailing_address_city_nm'],
                'mailing_address_state_nm': record['mailing_address_state_nm'],
                'mailing_address_zip_cd': record['mailing_address_zip_cd'],
                'broker_tier_nm': record['broker_tier_nm'],
                'contract_date_creation_date': record['contract_dt'],
                'primary_contact_name': record['primary_contact_nm'],
                'broker_email': record['broker_email'],
                'broker_phone_no': record['broker_phone_no'],
                'bdm_nm': record['bdm_nm'],
                'new_business_underwriter': record['new_business_uw_nm'],
                'renewal_underwriter': record['renewal_uw_nm'],
                'number_of_open_new_submissions': record['open_submissions_ct'],
                'one_year_actual_non_cat_loss_ratio': record['one_year_actual_non_cat_loss_ratio'],
                'two_year_ultimate_non_cat_loss_ratio': record['two_year_ultimate_non_cat_loss_ratio'],
                'five_year_non_cat_loss_ratio': record['five_year_non_cat_loss_ratio'],
                'number_of_binds_ytd': record['ytd_bind_ct'],
                'number_of_submissions_ytd': record['ytd_submission_ct'],
                'number_of_submissions_received_in_last_30_days': record['last30_days_submission_ct'],
                'hit_ratio': record['hit_ratio'],
                'number_of_offered_renewals': record['offered_renewal_ct'],
                'number_of_offered_renewals_over__50k': record['offered_renewal_over50k_ct'],
                'inforce_policy_ct': record['inforce_policy_ct'],
                'inforce_premium': record['inforce_premium_amt'],
                'of_target_yoy_inforce_premium': record['target_yoy_inforce_premium_pc'],
                'of_target_yoy_nb_premium': record['target_yoy_ytd_nb_prem_pc'],
                'of_target_2024_ytd_nb_premium': record['target_ytd_nb_premium_pc'],
                'of_target_2024_ytd_for_renewal_retention': record['target_ytd_renewal_retention_pc'],
                'broker_tier': record['broker_tier'],
                'national_broker2': record['national_agency_in'],
                'brokerage_type': record['broker_type'],
                'agency_status__new_': record['broker_status'],
                'agency_commission_tier': record['commission_tier'],
                'ytd_nb_premium_amt': record['ytd_nb_premium_amt'],
                'ytd_renewal_retention_pc': record['ytd_renewal_retention_pc'],
                'ytd_new_business_yacht_premium_amt': record['ytd_new_business_yacht_premium_amt']

                # 'bdm_email': record['bdm_email'],
                # 'create_ts': record['create_ts'],
                # 'update_ts': record['update_ts'],
                # 'etl_audit_sk': record['etl_audit_sk']
                }
            }
        
        if update:
            payload['id'] = record['hs_object_id']

        return payload


    def associate_records():
        Broker.broker_policy_associations()
        Broker.broker_quote_associations()
        Broker.broker_parent_child_associations()
        
    
    def broker_policy_associations():
        broker_policy_associations_df = Association.get_associations(table1='broker', id1='hs_company_id', table2='policy', id2='hs_object_id', key_column='broker_id')
        broker_policy_associations_payload = {"inputs": []}
 
        for index, row in broker_policy_associations_df.iterrows():
            from_id = row['hs_company_id']
            to_id = row['hs_object_id']
            association_type_id = Association.association_type_id['broker-policy']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            broker_policy_associations_payload['inputs'].append(record_payload)

        broker_policy_associations = hubspot.AssociationHandler('broker-policy-association', 'broker-policy-associations')
        broker_policy_associations.dispatch(broker_policy_associations_payload)


    def broker_quote_associations():
        broker_quote_associations_df = Association.get_associations(table1='broker', id1='hs_company_id', table2='quote', id2='hs_object_id', key_column='broker_id')
        broker_quote_associations_payload = {"inputs": []}
 
        for index, row in broker_quote_associations_df.iterrows():
            from_id = row['hs_object_id']
            to_id = row['hs_company_id']
            association_type_id = Association.association_type_id['broker-quote']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)
            broker_quote_associations_payload['inputs'].append(record_payload)

        broker_quote_associations = hubspot.AssociationHandler('broker-quote-association', 'broker-quote-associations')
        broker_quote_associations.dispatch(broker_quote_associations_payload)
    

    def broker_parent_child_associations():
        broker_parent_child_associations_df =  DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['broker_relation'])
        broker_quote_associations_payload = {"inputs": []}
 
        for index, row in broker_parent_child_associations_df.iterrows():
            from_id = Broker.return_broker_hs_id_for_update(row['parent_broker_id']) 
            to_id = Broker.return_broker_hs_id_for_update(row['child_broker_id'])
            association_type_id = Association.association_type_id['broker-parent-child']
            record_payload = Association.build_association_payload(from_id, to_id, association_type_id)# association_category='HUBSPOT_DEFINED') 
            broker_quote_associations_payload['inputs'].append(record_payload)

        broker_quote_associations = hubspot.AssociationHandler('broker-parent-child-association', 'broker-parent-child-associations')
        broker_quote_associations.dispatch(broker_quote_associations_payload)