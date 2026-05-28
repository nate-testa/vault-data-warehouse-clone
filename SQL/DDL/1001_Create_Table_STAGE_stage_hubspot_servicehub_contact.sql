IF NOT EXISTS
(
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'stage_hubspot_servicehub_contact')
BEGIN

CREATE TABLE [edw_stage].[stage_hubspot_servicehub_contact] (
    -- Identity
    [hs_object_id]                          NVARCHAR(4000)  NULL,
    [first_name]                            NVARCHAR(4000)  NULL,
    [last_name]                             NVARCHAR(4000)  NULL,
    [email]                                 NVARCHAR(4000)  NULL,
    [hs_email_domain]                       NVARCHAR(4000)  NULL,
    [phone]                                 NVARCHAR(4000)  NULL,
    [company]                               NVARCHAR(4000)  NULL,
    [created_date]                          DATETIME2(7)    NULL,
    [hs_last_modified_date]                 DATETIME2(7)    NULL,
    [lifecycle_stage]                        NVARCHAR(4000)  NULL,
    [hs_lead_status]                        NVARCHAR(4000)  NULL,
    [hs_owner_id]                           NVARCHAR(4000)  NULL,
    [hs_created_by_user_id]                 NVARCHAR(4000)  NULL,
    -- Source / Record origin
    [hs_object_source_label]                NVARCHAR(4000)  NULL,
    [hs_object_source_detail_1]             NVARCHAR(4000)  NULL,
    -- Analytics
    [hs_analytics_source]                   NVARCHAR(4000)  NULL,
    [hs_analytics_source_data_1]            NVARCHAR(4000)  NULL,
    [hs_analytics_source_data_2]            NVARCHAR(4000)  NULL,
    [hs_analytics_first_timestamp]          DATETIME2(7)    NULL,
    [hs_analytics_num_visits]               NVARCHAR(4000)  NULL,
    [hs_analytics_num_page_views]           NVARCHAR(4000)  NULL,
    [hs_analytics_average_page_views]       NVARCHAR(4000)  NULL,
    [hs_analytics_num_event_completions]    NVARCHAR(4000)  NULL,
    [hs_latest_source]                      NVARCHAR(4000)  NULL,
    [hs_latest_source_data_1]               NVARCHAR(4000)  NULL,
    [hs_latest_source_data_2]               NVARCHAR(4000)  NULL,
    [hs_latest_source_date]                 DATETIME2(7)    NULL,
    -- Marketing
    [hs_marketable_status]                  NVARCHAR(4000)  NULL,
    [hs_marketable_reason_type]             NVARCHAR(4000)  NULL,
    -- Scoring
    [hs_predictive_contact_score_v2]        NVARCHAR(4000)  NULL,
    [hs_predictive_scoring_tier]            NVARCHAR(4000)  NULL,
    -- Engagement
    [hs_sales_last_activity_date]           DATETIME2(7)    NULL,
    [hs_sales_first_engagement_date]        DATETIME2(7)    NULL,
    [hs_sales_first_engagement_desc]        NVARCHAR(4000)  NULL,
    [hs_sales_first_engagement_object_type] NVARCHAR(4000)  NULL,
    [hs_sales_last_email_replied_date]      DATETIME2(7)    NULL,
    [hs_time_to_first_engagement]           NVARCHAR(4000)  NULL,
    -- Deals
    [first_deal_created_date]               DATETIME2(7)    NULL,
    [hs_time_between_contact_creation_and_deal_creation] NVARCHAR(4000) NULL,
    -- ETL metadata
    [create_ts]                             DATETIME2(7)    NULL
);
END ;
