from src.logger import get_logger
import src.timetracking as timetracking
import constants

import pyodbc
import sqlite3


logger = get_logger(__name__)


class CompanyGoal:

    def load_to_edw(timestamp):
        logger.info(f'company goal sync to edw started')
        data = CompanyGoal.get_data_from_staging_table(timestamp)
        if data is not None:
            for record in data:
                try:
                    CompanyGoal.create_edw_table_record(record)
                    logger.info(f'company goal record successfully processed: {record}')
            
                except Exception as e:
                    logger.error(f'error loading {record} into edw: {e}')


    def get_data_from_staging_table(timestamp):
        formatted_timestamp = timetracking.format_timestamp_for_staging_query(timestamp)
        try:
            sql = f'''
            SELECT * FROM company_goal WHERE last_activity_date >= '{formatted_timestamp}'
            '''
            conn = sqlite3.connect(constants.company_goal_staging_table_path)
            cursor = conn.cursor()
            query = cursor.execute(sql)
            results = query.fetchall()
            conn.close()
            if results:
                logger.info(f'company goals retrieved from staging table: {results}')
                return results
            else:
                logger.info('company goals: no new entries in staging table.')
                return []
            
        except Exception as e:
            logger.error(f'error while returning company goals from staging table: {e}')
        

    def create_edw_table_record(payload):
        try:
            sql = f'''
                INSERT INTO edw_stage.hubspot_company_goals (
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
                '{payload[0]}', 
                '{payload[1]}',
                '{payload[2]}',
                '{payload[3]}',
                '{payload[4]}',
                '{payload[5]}',
                '{payload[6]}',
                '{payload[7]}'
                )
            '''
            CompanyGoal.insert_data_into_edw_table(sql)
            logger.info(f'company goal record successfully created in edw: {payload}')

        except Exception as e:
            logger.error(f'error while inserting company goal record into edw: {e}')


    def insert_data_into_edw_table(sql_query):
        try:
            conn = pyodbc.connect(constants.connection_string)
            cursor = conn.cursor()
            cursor.execute(sql_query)
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f'error while loading company goal data into edw: {e}')
        