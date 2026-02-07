from dotenv import load_dotenv
import os

load_dotenv()

policy_object_id = '2-34924470'
hs_token = os.getenv('HSTOKEN')
id_map_path = r'/home/vphubspotadmin/hs-integration/id_map.db'  
time_tracking_file_path = '/home/vphubspotadmin/hs-integration/timetracking.txt'
log_folder_path = '/home/vphubspotadmin/hs-integration/logs' 
# id_map_path = rf'{os.getcwd()}\\id_map.db'  
# time_tracking_file_path = f'{os.getcwd()}\\timetracking.txt'
# log_folder_path = f'{os.getcwd()}\\logs'

HOST = os.getenv('HOST')
USERNAME = os.getenv('USERNAME')
PASS = os.getenv('PASS')
DB = os.getenv('DB')

hub_api = 'https://api.hubapi.com'  

# Email Report Configuration
# Options: 'both', 'statistics_only', 'errors_only'
# - 'both': Include both statistics and error/warning tables (default)
# - 'statistics_only': Only show object processing statistics
# - 'errors_only': Only show error and warning tables
EMAIL_REPORT_MODE = 'both'

# Association configuration
# Set to True to automatically replace existing associations when limit is exceeded
# Set to False to skip and log the error (safer default)
REPLACE_ASSOCIATIONS_ON_LIMIT = False

object_map = {
    "customer": "contact",
    "producer": "contact",
    "broker": "company",
    "quote": "deal",
    "notes": "notes",
    "policy": policy_object_id
}


id_map_tables = {
    'broker': 'CREATE TABLE broker ( hs_company_id text NOT NULL, broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
    'customer': 'CREATE TABLE customer ( hs_contact_id text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'policy': 'CREATE TABLE policy ( hs_object_id text NOT NULL, policy_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'producer': 'CREATE TABLE producer ( hs_contact_id text NOT NULL, producer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'quote': 'CREATE TABLE quote ( hs_object_id text NOT NULL, quote_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
    'quote_note': 'CREATE TABLE quote_note ( hs_note_id text NOT NULL, quote_no text NOT NULL, created text NOT NULL, updated text NOT NULL )'
}