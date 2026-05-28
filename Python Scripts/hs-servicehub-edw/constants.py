from dotenv import load_dotenv
import os


load_dotenv()

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

# ETL control table — replaces flat file timestamp tracking
etl_control_table = 'edw_core.tetl_control'
etl_process_name = 'py_servicehub_edw'

HSTOKEN = os.getenv('HSTOKEN')
HOST = os.getenv('HOST')
USERNAME = os.getenv('USERNAME')
PASS = os.getenv('PASS')
DB = os.getenv('DB')

driver = '{ODBC Driver 18 for SQL Server}'
connection_string = f'''DRIVER={driver};SERVER={HOST};DATABASE={DB};UID={USERNAME};PWD={PASS};'''

hs_headers = {
    'content-type': 'application/json',
    'Authorization': f'Bearer {HSTOKEN}'
}

hubapi = 'https://api.hubapi.com'

# --- Ticket properties to pull from HubSpot (ALL from CSV export, 82 properties) ---
ticket_properties = [
    # Aircall
    'aircall_sms_direction',
    'aircall_sms_from',
    'aircall_sms_status',
    'aircall_sms_to',
    # Ticket activity
    'hs_last_closed_date',
    'hs_lastmodifieddate',
    'hs_ticket_reopened_at',
    # Ticket information - Identity
    'hs_object_id',
    'hs_ticket_id',
    'subject',
    'content',
    'createdate',
    # Pipeline / Status
    'hs_pipeline',
    'hs_pipeline_stage',
    'ticket_type',
    'ticket_subtype',
    'ticket_router',
    'hs_ticket_category',
    'hs_ticket_priority',
    'hs_resolution',
    # Subtypes
    'billing_subtype',
    'licensing_subtype',
    'claims_subtype_system_prompt',
    'commercial_claims_subtype_system_prompt',
    'concierge_subtype_system_prompt',
    # Source / Channel
    'source_type',
    'hs_object_source_label',
    'hs_object_source_detail_1',
    'hs_object_source_detail_2',
    'hs_object_source_detail_3',
    'hs_originating_channel_instance_id',
    'hs_originating_generic_channel_id',
    'hs_source_url',
    'hs_outbound_ticket',
    # Contact / Association
    'contact_type',
    'hs_all_associated_contact_emails',
    'policy_name',
    # Assignment / Ownership
    'hs_assigned_team_ids',
    'hubspot_owner_id',
    'hubspot_owner_assigneddate',
    'hubspot_team_id',
    'escalation_owner',
    'escalation_type',
    # Close / Resolution
    'closed_date',
    'closed_reason',
    'root_cause',
    # Activity dates
    'hs_lastactivitydate',
    'hs_lastcontacted',
    'hs_nextactivitydate',
    'last_reply_date',
    'first_agent_reply_date',
    # Message tracking
    'hs_last_message_received_at',
    'hs_last_message_sent_at',
    'hs_last_message_from_visitor',
    'hs_latest_message_is_thread_comment',
    'hs_first_agent_message_sent_by',
    'hs_is_one_touch_ticket',
    # Metrics / Counts
    'hs_num_times_contacted',
    'hs_number_of_touches',
    # SLA
    'hs_time_to_close_sla_at',
    'hs_time_to_close_sla_status',
    'hs_time_to_close_in_operating_hours',
    'hs_time_to_first_rep_assignment',
    'hs_time_to_first_response_sla_at',
    'hs_time_to_first_response_sla_status',
    'hs_time_to_first_response_in_operating_hours',
    'hs_time_to_next_response_sla_at',
    'hs_time_to_next_response_sla_status',
    'hs_sla_pause_status',
    'total_sla_window',
    'time_since_created',
    'time_to_close',
    'time_to_first_agent_reply',
    # Copied / Merged
    'hs_copied_at',
    'hs_copied_by_user',
    'hs_copied_from_ticket',
    'hs_copied_ticket_source',
    'hs_merged_object_ids',
    # Audit
    'hs_created_by_user_id',
    'hs_updated_by_user_id',
    'hs_customer_agent_ticket_status',
    'hs_tag_ids',
]

# --- Contact properties to pull from HubSpot (high fill-rate >10%) ---
contact_properties = [
    # Identity
    'hs_object_id',
    'firstname',
    'lastname',
    'email',
    'hs_email_domain',
    'phone',
    'company',
    'createdate',
    'hs_lastmodifieddate',
    'lifecyclestage',
    'hs_lead_status',
    'hubspot_owner_id',
    'hs_created_by_user_id',
    # Source / Record origin
    'hs_object_source_label',
    'hs_object_source_detail_1',
    # Analytics
    'hs_analytics_source',
    'hs_analytics_source_data_1',
    'hs_analytics_source_data_2',
    'hs_analytics_first_timestamp',
    'hs_analytics_num_visits',
    'hs_analytics_num_page_views',
    'hs_analytics_average_page_views',
    'hs_analytics_num_event_completions',
    'hs_latest_source',
    'hs_latest_source_data_1',
    'hs_latest_source_data_2',
    'hs_latest_source_timestamp',
    # Marketing
    'hs_marketable_status',
    'hs_marketable_reason_type',
    # Scoring
    'hs_predictivecontactscore_v2',
    'hs_predictivescoringtier',
    # Engagement
    'hs_last_sales_activity_timestamp',
    'hs_sa_first_engagement_date',
    'hs_sa_first_engagement_descr',
    'hs_sa_first_engagement_object_type',
    'hs_sales_email_last_replied',
    'hs_time_to_first_engagement',
    # Deals
    'first_deal_created_date',
    'hs_time_between_contact_creation_and_deal_creation',
]


# --- EDW table names ---
ticket_table = 'edw_stage.stage_hubspot_servicehub_ticket'
contact_table = 'edw_stage.stage_hubspot_servicehub_contact'

# --- HubSpot API property name → EDW column name mapping ---
# Only properties that differ are listed; unlisted ones keep the same name.
ticket_column_map = {
    'hs_last_closed_date':                  'hs_ticket_last_closed_date',
    'hs_lastmodifieddate':                  'hs_ticket_last_modified_date',
    'hs_ticket_reopened_at':                'hs_ticket_reopened_date',
    'subject':                              'hs_subject',
    'content':                              'hs_content',
    'createdate':                           'hs_created_date',
    'source_type':                          'hs_source_type',
    'hs_all_associated_contact_emails':     'hs_all_associated_contact_email',
    'hs_assigned_team_ids':                 'hs_assigned_team_id',
    'hubspot_owner_id':                     'hs_owner_id',
    'hubspot_owner_assigneddate':           'hs_owner_assigned_date',
    'hubspot_team_id':                      'hs_team_id',
    'hs_lastactivitydate':                  'hs_last_activity_date',
    'hs_lastcontacted':                     'hs_last_contacted_date',
    'hs_nextactivitydate':                  'hs_next_activity_date',
    'hs_last_message_received_at':          'hs_last_message_received_date',
    'hs_last_message_sent_at':              'hs_last_message_sent_date',
    'hs_number_of_touches':                 'hs_num_of_touches',
    'hs_time_to_close_sla_at':              'hs_time_to_close_sla_date',
    'hs_time_to_first_rep_assignment':      'hs_time_to_first_response_assignment',
    'hs_time_to_first_response_sla_at':     'hs_time_to_first_response_sla_date',
    'hs_time_to_next_response_sla_at':      'hs_time_to_next_response_sla_date',
    'hs_copied_at':                         'hs_copied_date',
    'hs_merged_object_ids':                 'hs_merged_object_id',
    'hs_tag_ids':                           'hs_tag_id',
}

contact_column_map = {
    'firstname':                            'first_name',
    'lastname':                             'last_name',
    'createdate':                           'created_date',
    'hs_lastmodifieddate':                  'hs_last_modified_date',
    'lifecyclestage':                       'lifecycle_stage',
    'hubspot_owner_id':                     'hs_owner_id',
    'hs_latest_source_timestamp':           'hs_latest_source_date',
    'hs_predictivecontactscore_v2':         'hs_predictive_contact_score_v2',
    'hs_predictivescoringtier':             'hs_predictive_scoring_tier',
    'hs_last_sales_activity_timestamp':     'hs_sales_last_activity_date',
    'hs_sa_first_engagement_date':          'hs_sales_first_engagement_date',
    'hs_sa_first_engagement_descr':         'hs_sales_first_engagement_desc',
    'hs_sa_first_engagement_object_type':   'hs_sales_first_engagement_object_type',
    'hs_sales_email_last_replied':          'hs_sales_last_email_replied_date',
}
