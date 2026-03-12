from dotenv import load_dotenv
import os

load_dotenv()

# Environment detection: 'PRODUCTION' or 'SANDBOX' (default)
ENVIRONMENT = os.getenv('ENVIRONMENT', 'SANDBOX').upper()

# Environment-specific configuration
if ENVIRONMENT == 'PRODUCTION':
    policy_object_id = '2-34924470'
    hs_token = os.getenv('HSTOKEN')
else:  # SANDBOX (default)
    policy_object_id = '2-33911930'
    hs_token = os.getenv('HSSANDBOXKEY')

# Use current working directory for paths (allows DAG to control location)
id_map_path = rf'{os.getcwd()}/id_map.db'  
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
else:  # SANDBOX
    LIMITED_ASSOCIATION_TYPES = [
        45,  # quote-producer
        43,  # policy-producer
        28,  # customer-quote
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
    'broker': 'CREATE TABLE broker ( hs_company_id text NOT NULL, broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
    'customer': 'CREATE TABLE customer ( hs_contact_id text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'policy': 'CREATE TABLE policy ( hs_object_id text NOT NULL, policy_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, producer_id text, email text, created text NOT NULL, updated text NOT NULL )',
    'producer': 'CREATE TABLE producer ( hs_contact_id text NOT NULL, producer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'quote': 'CREATE TABLE quote ( hs_object_id text NOT NULL, quote_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, producer_id text, created text NOT NULL, updated text NOT NULL )',
    'quote_note': 'CREATE TABLE quote_note ( hs_note_id text NOT NULL, quote_no text NOT NULL, created text NOT NULL, updated text NOT NULL )'
}