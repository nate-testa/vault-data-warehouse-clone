from dotenv import load_dotenv
import os


load_dotenv()

company_goal_staging_table_path = f'/home/vphubspotadmin/hs-edw-writeback/company_goal_staging.db'
path_to_timetracking_file = f'/home/vphubspotadmin/hs-edw-writeback/previous_run_timestamp.txt'
# company_goal_staging_table_path = f'{os.getcwd()}/company_goal_staging.db'
# path_to_timetracking_file = f'{os.getcwd()}/previous_run_timestamp.txt'
root_directory = os.getcwd()


HSSANDBOXKEY = os.getenv('HSTOKEN')
HOST = os.getenv('HOST')
USERNAME = os.getenv('USERNAME')
PASS = os.getenv('PASS')
DB = os.getenv('DB')

driver = '{ODBC Driver 18 for SQL Server}'
connection_string = f'''
DRIVER={driver};SERVER={HOST};DATABASE={DB};UID={USERNAME};PWD={PASS};
'''

hs_headers = {
    'content-type': 'application/json',
    'Authorization': F'Bearer {HSSANDBOXKEY}'
}

hubapi = 'https://api.hubapi.com'

company_goal_fields_to_query = [
    'n2025_new_business_premium_commitment',
    'n2025_monthly_quote_commitment',
    'n2025_monthly_new_business_policy_count_comminitment',
    'n2025_policy_in_force_renewal_retention_commitment',
    'n2025_1_year_actual_non_cat_loss_ratio_commitment',
    'n2025_hit_ratio_commitment'
]

# sql query to create company goal staging table
'''
CREATE TABLE company_goal ( 
    agency_code text NOT NULL,
    last_activity_date text,
    n2025_new_business_premium_commitment text,
    n2025_monthly_quote_commitment text,
    n2025_monthly_new_business_policy_count_comminitment text,
    n2025_policy_in_force_renewal_retention_commitment text,
    n2025_1_year_actual_non_cat_loss_ratio_commitment text,
    n2025_hit_ratio_commitment text
)
'''










