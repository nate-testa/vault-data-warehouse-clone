from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.logger import get_logger
import shared.hubspot as hubspot

import sqlite3

logger = get_logger(__name__)



class Quote:
    
    def sync_to_hubspot():
        quote_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['quote'])

        if not quote_df.empty:
            results = quote_df.apply(Quote.process_row, axis=1)
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

            update_records = hubspot.UpdateRecordsHandler('deals', 'quote_update')
            update_records.dispatch(update_batch_payload)
            create_records = hubspot.CreateRecordsHandler('deals', 'quote_create')
            create_records.dispatch(create_batch_payload)
    

    def process_row(row):
        hs_object_id = Quote.return_quote_hs_id_for_update(row['quote_no'])
        
        if hs_object_id:
            row['hs_object_id'] = hs_object_id
            record_payload = Quote.build_payload(row, update=True)
            return 'update', record_payload
        else:
            record_payload = Quote.build_payload(row, update=False)
            return 'create', record_payload


    def return_quote_hs_id_for_update(quote_no):
        conn = sqlite3.connect(id_map_path)
        cursor = conn.cursor()
        sql = f'''
        SELECT hs_object_id FROM quote WHERE quote_no = '{quote_no}'
        '''
        query = cursor.execute(sql)
        result = query.fetchall()
        conn.close()

        if result:
            return result[0][0]
        else:
            return '' 


    def is_in_united_states(input_string):
        checked_value = input_string.lower()

        if checked_value == 'united states':
            return True
        if checked_value == 'us':
            return True
        if checked_value == 'usa':
            return True
        else:
            return False


    def build_payload(record, update):
        domestic_account = Quote.is_in_united_states(record['risk_country_nm'])
        
        if domestic_account:
            state_field = record['risk_state_cd']
            country_field = 'US'
        else:
            state_field = ''
            # since risk state is passing some country values, if it's an international address then pass that to risk country field in hubspot
            country_field = record['risk_state_cd']

        if record['recampaign_in']:
            if record['recampaign_in'] == 'N':
                record['recampaign_in'] = 'No'
            elif record['recampaign_in'] == 'Y':
                record['recampaign_in'] = 'Yes'
            else:
                record['recampaign_in'] = ''
         
        if record['vip_in']:
            if record['vip_in'] == 'N':
                record['vip_in'] = 'No'
            if record['vip_in'] == 'Y':
                record['vip_in'] = 'Yes'
            else:
                record['vip_in'] = ''

        record['dealname'] = f"{record['quote_no']} - {record['insured_first_nm']} {record['insured_last_nm']}"

        payload = {
            'properties': {
                'policy_number': record['quote_no'],
                'broker_id': record['broker_id'],
                'customer_id': record['customer_id'],
                'dealname': record['dealname'],
                'broker_name': record['broker_nm'],
                'effective_date': record['effective_dt'],
                'expiration_date': record['expiration_dt'],
                'producer_nm': record['producer_nm'],
                'bdm_nm': record['bdm_nm'],
                'insured_first_nm': record['insured_first_nm'],
                'insured_last_nm': record['insured_last_nm'],
                'underwriter_name': record['underwriter_nm'],
                'underwriter_company_name': record['uw_company_nm'],
                'risk_address_line_1': record['risk_address_line_1'],
                'risk_address_line_2': record['risk_address_line_2'],
                'risk_address_city': record['risk_city_nm'],
                'risk_address_zip': record['risk_zip_cd'],
                'risk_address_state': state_field,
                'risk_country_nm': country_field,
                'amount': record['premium_amt'],
                'claim_count': record['claim_ct'],
                'description': record['note_desc'],
                'rol_on_lost_business': record['rol_on_lost_business'],
                'lost_company': record['lost_company'],
                'reason_quote_not_taken': record['reason_quote_not_taken'],
                'construction': record['construction'],
                'dwelling_limit_amt': record['dwelling_limit_amt'],
                'contents_limit_amt': record['contents_limit_amt'],
                'other_structures_limit_amt': record['other_structures_limit_amt'],
                'loss_of_use_limit_amt': record['loss_of_use_limit_amt'],
                'total_insured_value_amt': record['total_insured_value_amt'],
                'home_condo_roof_covering': record['roof_covering'],
                'home_condo_roof_year': record['roof_updated_year'],
                'insurance_score': record['insurance_score'],
                'pel_liability_limit': record['pel_limit_amt'],
                'auto_liability_limit_amt': record['auto_liability_limit_amt'],
                'total_blanket_limit_amt': record['total_blanket_limit_amt'],
                'total_scheduled_limit_amt': record['total_scheduled_limit_amt'],
                'collections_coverage_type': record['collections_coverage_type'],
                'quote_status': record['quote_status'],
                'recampaign_in': record['recampaign_in'],
                'vip_in': record['vip_in'],
                'national_agency_in': record['national_agency_in'],
                'transaction_type': record['transaction_type'],
                'primary_home_risk_address': record['primary_home_risk_address'],
                'primary_home_policy_effective_dt': record['primary_home_policy_effective_dt'],
                'primary_home_policy_expiration_dt': record['primary_home_policy_expiration_dt'],
                'primary_home_carrier_nm': record['primary_home_carrier_nm'],
                'primary_home_coverage_a_threshold': record['primary_home_coverage_a_threshold'],
                'occupancy_type': record['occupancy_type'],
                'new_client_for_agency_in': record['new_client_for_agency_in'],
                'current_underlying_company_nm': record['current_underlying_company_nm'],
                'target_account': record['target_account'],
                'close_reason_desc': record['close_reason_desc'],
                'monoline_in': record['monoline_in'],
                'broker_state': record['broker_state'],
                'insured_nm': record['insured_nm'],
                'retroactive_dt_desc': record['retroactive_dt_desc'],
                'prior_or_pending_dt_desc': record['prior_or_pending_dt_desc'],
                'primary_carrier_nm': record['primary_carrier_nm'],
                'per_claim_retention_amt': record['per_claim_retention_amt'],
                'aggregate_retention_amt': record['aggregate_retention_amt'],
                'threafter_retention': record['threafter_retention'],
                'vault_premium_amt': record['vault_premium_amt'],
                'vault_commission_amt': record['vault_commission_amt'],
                'total_layer_premium_amt': record['total_layer_premium_amt'],
                'vault_per_claim_policy_limit_amt': record['vault_per_claim_policy_limit_amt'],
                'vault_aggregate_policy_limit_amt': record['vault_aggregate_policy_limit_amt'],
                'total_layer_per_claim_policy_limit_amt': record['total_layer_per_claim_policy_limit_amt'],
                'total_layer_aggregate_policy_limit_amt': record['total_layer_aggregate_policy_limit_amt'],
                'total_aggregate_attachment_amt': record['total_aggregate_attachment_amt'],
                'total_per_claim_attachment_amt': record['total_per_claim_attachment_amt'],
                'quote_business_type': record['quote_business_type']
                
                # 'pipeline': record['pipeline'],
                # 'dealstage': record['dealstage'],
                # 'create_ts': record['create_ts'],
                # 'update_ts': record['update_ts'],
                # 'etl_audit_sk': record['etl_audit_sk']
            }
        } 

        if update:
            payload['id'] = record['hs_object_id']
        
        return payload
        


        


          

