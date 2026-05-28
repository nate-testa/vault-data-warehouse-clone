IF NOT EXISTS
(
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'stage_hubspot_servicehub_ticket')
BEGIN

CREATE TABLE [edw_stage].[stage_hubspot_servicehub_ticket] (
    -- Aircall
    [aircall_sms_direction]                 NVARCHAR(4000)  NULL,
    [aircall_sms_from]                      NVARCHAR(4000)  NULL,
    [aircall_sms_status]                    NVARCHAR(4000)  NULL,
    [aircall_sms_to]                        NVARCHAR(4000)  NULL,
    -- Ticket activity
    [hs_ticket_last_closed_date]            DATETIME2(7)    NULL,
    [hs_ticket_last_modified_date]          DATETIME2(7)    NULL,
    [hs_ticket_reopened_date]               DATETIME2(7)    NULL,
    -- Identity
    [hs_object_id]                          NVARCHAR(4000)  NULL,
    [hs_ticket_id]                          NVARCHAR(4000)  NULL,
    [hs_subject]                            NVARCHAR(4000)  NULL,
    [hs_content]                            NVARCHAR(MAX)   NULL,
    [hs_created_date]                       DATETIME2(7)    NULL,
    -- Pipeline / Status
    [hs_pipeline]                           NVARCHAR(4000)  NULL,
    [hs_pipeline_stage]                     NVARCHAR(4000)  NULL,
    [ticket_type]                           NVARCHAR(4000)  NULL,
    [ticket_subtype]                        NVARCHAR(4000)  NULL,
    [ticket_router]                         NVARCHAR(4000)  NULL,
    [hs_ticket_category]                    NVARCHAR(4000)  NULL,
    [hs_ticket_priority]                    NVARCHAR(4000)  NULL,
    [hs_resolution]                         NVARCHAR(4000)  NULL,
    -- Subtypes
    [billing_subtype]                       NVARCHAR(4000)  NULL,
    [licensing_subtype]                     NVARCHAR(4000)  NULL,
    [claims_subtype_system_prompt]          NVARCHAR(MAX)   NULL,
    [commercial_claims_subtype_system_prompt] NVARCHAR(MAX) NULL,
    [concierge_subtype_system_prompt]       NVARCHAR(MAX)   NULL,
    -- Source / Channel
    [hs_source_type]                        NVARCHAR(4000)  NULL,
    [hs_object_source_label]                NVARCHAR(4000)  NULL,
    [hs_object_source_detail_1]             NVARCHAR(4000)  NULL,
    [hs_object_source_detail_2]             NVARCHAR(4000)  NULL,
    [hs_object_source_detail_3]             NVARCHAR(4000)  NULL,
    [hs_originating_channel_instance_id]    NVARCHAR(4000)  NULL,
    [hs_originating_generic_channel_id]     NVARCHAR(4000)  NULL,
    [hs_source_url]                         NVARCHAR(4000)  NULL,
    [hs_outbound_ticket]                    NVARCHAR(4000)  NULL,
    -- Contact / Association
    [contact_type]                          NVARCHAR(4000)  NULL,
    [hs_all_associated_contact_email]       NVARCHAR(MAX)   NULL,
    [policy_name]                           NVARCHAR(4000)  NULL,
    -- Assignment / Ownership
    [hs_assigned_team_id]                   NVARCHAR(4000)  NULL,
    [hs_owner_id]                           NVARCHAR(4000)  NULL,
    [hs_owner_assigned_date]                DATETIME2(7)    NULL,
    [hs_team_id]                            NVARCHAR(4000)  NULL,
    [escalation_owner]                      NVARCHAR(4000)  NULL,
    [escalation_type]                       NVARCHAR(4000)  NULL,
    -- Close / Resolution
    [closed_date]                           DATETIME2(7)    NULL,
    [closed_reason]                         NVARCHAR(4000)  NULL,
    [root_cause]                            NVARCHAR(4000)  NULL,
    -- Activity dates
    [hs_last_activity_date]                 DATETIME2(7)    NULL,
    [hs_last_contacted_date]                DATETIME2(7)    NULL,
    [hs_next_activity_date]                 DATETIME2(7)    NULL,
    [last_reply_date]                       DATETIME2(7)    NULL,
    [first_agent_reply_date]                DATETIME2(7)    NULL,
    -- Message tracking
    [hs_last_message_received_date]         DATETIME2(7)    NULL,
    [hs_last_message_sent_date]             DATETIME2(7)    NULL,
    [hs_last_message_from_visitor]          NVARCHAR(4000)  NULL,
    [hs_latest_message_is_thread_comment]   NVARCHAR(MAX)   NULL,
    [hs_first_agent_message_sent_by]        NVARCHAR(4000)  NULL,
    [hs_is_one_touch_ticket]                NVARCHAR(4000)  NULL,
    -- Metrics / Counts
    [hs_num_times_contacted]                NVARCHAR(4000)  NULL,
    [hs_num_of_touches]                     NVARCHAR(4000)  NULL,
    -- SLA
    [hs_time_to_close_sla_date]            DATETIME2(7)    NULL,
    [hs_time_to_close_sla_status]          NVARCHAR(4000)  NULL,
    [hs_time_to_close_in_operating_hours]  NVARCHAR(4000)  NULL,
    [hs_time_to_first_response_assignment] NVARCHAR(4000)  NULL,
    [hs_time_to_first_response_sla_date]   DATETIME2(7)    NULL,
    [hs_time_to_first_response_sla_status] NVARCHAR(4000)  NULL,
    [hs_time_to_first_response_in_operating_hours] NVARCHAR(4000) NULL,
    [hs_time_to_next_response_sla_date]    DATETIME2(7)    NULL,
    [hs_time_to_next_response_sla_status]  NVARCHAR(4000)  NULL,
    [hs_sla_pause_status]                  NVARCHAR(4000)  NULL,
    [total_sla_window]                     NVARCHAR(4000)  NULL,
    [time_since_created]                   NVARCHAR(4000)  NULL,
    [time_to_close]                        NVARCHAR(4000)  NULL,
    [time_to_first_agent_reply]            NVARCHAR(4000)  NULL,
    -- Copied / Merged
    [hs_copied_date]                       DATETIME2(7)    NULL,
    [hs_copied_by_user]                    NVARCHAR(4000)  NULL,
    [hs_copied_from_ticket]                NVARCHAR(4000)  NULL,
    [hs_copied_ticket_source]              NVARCHAR(4000)  NULL,
    [hs_merged_object_id]                  NVARCHAR(4000)  NULL,
    -- Audit
    [hs_created_by_user_id]                NVARCHAR(4000)  NULL,
    [hs_updated_by_user_id]                NVARCHAR(4000)  NULL,
    [hs_customer_agent_ticket_status]      NVARCHAR(4000)  NULL,
    [hs_tag_id]                            NVARCHAR(4000)  NULL,
    -- ETL metadata
    [create_ts]                            DATETIME2(7)    NULL
);
END ;