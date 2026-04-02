from dotenv import load_dotenv
import os

load_dotenv()

# Environment detection: 'PRODUCTION', 'UAT', or 'SANDBOX' (default)
ENVIRONMENT = os.getenv('ENVIRONMENT', 'SANDBOX').upper()

# Environment-specific configuration
if ENVIRONMENT == 'PRODUCTION':
    policy_object_id = '2-34924470'
    hs_token = os.getenv('HSTOKEN')
else:  # UAT
    policy_object_id = '2-59012341'
    hs_token = os.getenv('HSSANDBOXKEY')

# Use current working directory for paths (allows DAG to control location)
# id_map_path is no longer used - id_map tables are now in SQL Server (edw_hubspot schema)
# See shared/id_map_db.py for connection details
time_tracking_file_path = f'{os.getcwd()}/timetracking.txt' 
log_folder_path = f'{os.getcwd()}/logs'

HOST = os.getenv('HOST')
USERNAME = os.getenv('USERNAME')
PASS = os.getenv('PASS')
DB = os.getenv('DB')


hub_api = 'https://api.hubapi.com'  

# Association configuration
# Set to True to automatically replace existing associations when limit is exceeded
# Set to False to skip and log the error (safer default)
REPLACE_ASSOCIATIONS_ON_LIMIT = False

# Producer Association Change Detection
# Set to True to automatically detect and clean up old producer associations when producer_id changes
# This prevents duplicate producer associations when a quote/policy is reassigned to a different producer
# Example: If a quote moves from Producer A to Producer B, the old association to A is deleted
CLEAN_CHANGED_PRODUCER_ASSOCIATIONS = True

# Pre-flight Association Check
# Set to True to check existing associations BEFORE attempting the PUT call.
# Only applies to association types listed in LIMITED_ASSOCIATION_TYPES below.
# This avoids wasted API calls on requests guaranteed to fail due to limit conflicts,
# and provides early classification of cross-type vs same-type conflicts.
# Trade-off: adds one GET call per limited association attempt.
PREFLIGHT_ASSOCIATION_CHECK = True

# Cumulative Failure Tracking
# Set to True to save association failure counts to a JSON history file after each run.
# This enables run-over-run trend logging (e.g., "failures increased by 449 since last run").
# History is stored in logs/association_failure_history.json (last 30 runs).
TRACK_CUMULATIVE_FAILURES = False

# Association types that have a limit of 1 (one-to-one) in HubSpot.
# Only these types get enhanced diagnostics (pre-flight check, cross-type vs same-type
# conflict classification, full association dump on failure).
# Other types (many-to-many) skip the extra GET calls entirely.
if ENVIRONMENT == 'PRODUCTION':
    LIMITED_ASSOCIATION_TYPES = [
        37,  # quote-producer
        39,  # policy-producer
        30,  # customer-quote
    ]
else:  # UAT
    LIMITED_ASSOCIATION_TYPES = [
        22,  # quote-producer
        30,  # policy-producer
        26,  # customer-quote
    ]

# Email Report Configuration
# Options: 'both', 'statistics_only', 'errors_only'
# - 'both': Include both statistics and error/warning tables (default)
# - 'statistics_only': Only show object processing statistics
# - 'errors_only': Only show error and warning tables
EMAIL_REPORT_MODE = 'both'

object_map = {
    "customer": "contact",
    "producer": "contact",
    "broker": "company",
    "quote": "deal",
    "notes": "notes",
    "policy": policy_object_id
}


id_map_tables = {
    'broker': 'CREATE TABLE edw_hubspot.broker ( hs_company_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'customer': 'CREATE TABLE edw_hubspot.customer ( hs_contact_id NVARCHAR(50) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'policy': 'CREATE TABLE edw_hubspot.policy ( hs_object_id NVARCHAR(50) NOT NULL, policy_no NVARCHAR(100) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50), email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'producer': 'CREATE TABLE edw_hubspot.producer ( hs_contact_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'quote': 'CREATE TABLE edw_hubspot.quote ( hs_object_id NVARCHAR(50) NOT NULL, quote_no NVARCHAR(100) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'quote_note': 'CREATE TABLE edw_hubspot.quote_note ( hs_note_id NVARCHAR(50) NOT NULL, quote_no NVARCHAR(100) NOT NULL, created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )'
}