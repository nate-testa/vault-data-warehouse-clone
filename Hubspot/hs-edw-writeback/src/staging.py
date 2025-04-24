import src.timetracking as timetracking
import constants
import sqlite3
import json
import requests
import time

from src.logger import get_logger
from collections import defaultdict

logger = get_logger(__name__)

class Staging:

    def sync_to_staging_table(timestamp):
        logger.info(f'company goal staging started')
        fields_to_query = constants.company_goal_fields_to_query
        results = {'results': []}
        merged_data = defaultdict(dict)

        #### iterate over fields to query and populate the results list inside the results dictionary
        for field in fields_to_query: 
            unix_timestamp = timetracking.format_unix_timestamp_for_hs_company_goals_query(timestamp)
            query = Staging.build_company_goals_query(unix_timestamp, field)
            company_goals_response = Staging.get_all_company_goals_modified_after_timestamp(unix_timestamp, query)
            time.sleep(0.5)
            results['results'].append(company_goals_response)

        if results:
            #### iterate over results list inside results dict to create unified json object for each id
            for result_set in results['results']:
                for result in result_set:
                    obj_id = result['id']
                    properties = result['properties']
                    for key, value in properties.items():
                        merged_data[obj_id][key] = value

            #### build staging table payload and create record in staging table
            for obj_id, properties in merged_data.items():
                payload = Staging.build_staging_table_payload(properties)
                created = Staging.create_staging_table_record(payload)

    def create_staging_table_record(payload):
        try:
            sql = f'''
                INSERT INTO company_goal (
                    agency_code, 
                    last_activity_date,
                    target_2024_gross_nb_premium_ytd,
                    target_2024_policy_inforce_renewal_retention__,
                    target_monthly_nb_quote_commitment__,
                    target_monthly_nb_policy_counts,
                    target_growth_2024_inforce_premium_over_last_year,
                    target_growth_2024_nb_premium_over_last_year
                )
                VALUES (
                '{payload['agency_code']}', 
                '{payload['last_activity_date']}',
                '{payload['target_2024_gross_nb_premium_ytd']}',
                '{payload['target_2024_policy_inforce_renewal_retention__']}',
                '{payload['target_monthly_nb_quote_commitment__']}',
                '{payload['target_monthly_nb_policy_counts']}',
                '{payload['target_growth_2024_inforce_premium_over_last_year']}',
                '{payload['target_growth_2024_nb_premium_over_last_year']}'
                )
            '''
            Staging.insert_record_into_staging_table(sql)
            logger.info(f'company goals payload successfully created in staging table: {payload}')
            return True

        except Exception as e:
            logger.error(f'error while inserting company goal record into staging table: {e}')
            return False


    def insert_record_into_staging_table(sql_query):
        try:
            conn = sqlite3.connect(constants.company_goal_staging_table_path)
            cursor = conn.cursor()
            cursor.execute(sql_query)
            conn.commit()
            conn.close()

        except Exception as e:
            logger.error(f'error while inserting record into staging table: {e}')


    def build_staging_table_payload(properties):
        try:
            payload = {
                'agency_code': properties['broker_id'],
                'last_activity_date': properties['hs_lastmodifieddate'],
                'target_2024_gross_nb_premium_ytd': properties['target_2024_gross_nb_premium_ytd'],
                'target_2024_policy_inforce_renewal_retention__': properties['target_2024_policy_inforce_renewal_retention__'],
                'target_monthly_nb_quote_commitment__': properties['target_monthly_nb_quote_commitment__'],
                'target_monthly_nb_policy_counts': properties['target_monthly_nb_policy_counts'],
                'target_growth_2024_inforce_premium_over_last_year': properties['target_growth_2024_inforce_premium_over_last_year'],
                'target_growth_2024_nb_premium_over_last_year': properties['target_growth_2024_nb_premium_over_last_year']
            }
            logger.info(f"company goal staging table payload built successfully for {properties['broker_id']}: {payload}")   
            return payload
        
        except Exception as e:
            logger.error(f"error while building company goal staging table payload for {properties['broker_id']}: {e}")


    def get_all_company_goals_modified_after_timestamp(timestamp, query):
        try: 
            endpoint = f'crm/v3/objects/companies/search'
            url = f"{constants.hubapi}/{endpoint}"
            data = json.dumps(query)
            response = requests.post(url=url, headers=constants.hs_headers, data=data)
            results = []
            if response.ok: 
                json_response = response.json()
                results = json_response['results'] if 'results' in json_response else []
                logger.info(json_response)   
            return results
        
        except Exception as e:
            logger.error(f'error while requesting company goals modified since last run: {e}')


    def build_company_goals_query(unix_timestamp, field):
        try:
            json_data = {
                'limit': 200,
                'properties': [
                    'id',
                    'broker_id',
                    'hs_lastmodifieddate',
                    f'{field}'
                ],
                'filterGroups': [
                ],
            }
            query_data = {'filters': [
                {'propertyName': 'write_back_company_goal', 'value': f'{unix_timestamp}', 'operator': 'GT'}
                ]}
            json_data['filterGroups'].append(query_data)
            logger.info(f'company goal query successfully built for {field}: {json_data}')
            return json_data
        
        except Exception as e:
            logger.error(f'error while building company goals query for {field}: {e}')
    