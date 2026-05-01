IF NOT EXISTS
(
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'stage_aircall_list_all_calls')
BEGIN

CREATE TABLE [edw_stage].[stage_aircall_list_all_calls] (
    [id]                        NVARCHAR(4000)  NULL,
    [sid]                       NVARCHAR(4000)  NULL,
    [direct_link]               NVARCHAR(4000)  NULL,
    [direction]                 NVARCHAR(4000)  NULL,
    [status]                    NVARCHAR(4000)  NULL,
    [missed_call_reason]        NVARCHAR(4000)  NULL,
    [started_at]                BIGINT          NULL,
    [answered_at]               BIGINT          NULL,
    [ended_at]                  BIGINT          NULL,
    [duration]                  INT             NULL,
    [archived]                  BIT             NULL,
    [cost]                      DECIMAL(15,2)   NULL,
    [voicemail]                 NVARCHAR(4000)  NULL,
    [recording]                 NVARCHAR(4000)  NULL,
    [asset]                     NVARCHAR(4000)  NULL,
    [raw_digits]                NVARCHAR(4000)  NULL,
    [user_json]                 NVARCHAR(MAX)   NULL,
    [contact_json]              NVARCHAR(MAX)   NULL,
    [assigned_to_json]          NVARCHAR(MAX)   NULL,
    [transferred_by_json]       NVARCHAR(MAX)   NULL,
    [transferred_to_json]       NVARCHAR(MAX)   NULL,
    [comments_json]             NVARCHAR(MAX)   NULL,
    [number_json]               NVARCHAR(MAX)   NULL,
    [teams_json]                NVARCHAR(MAX)   NULL,
    [tags_json]                 NVARCHAR(MAX)   NULL,
    [recording_short_url]       NVARCHAR(4000)  NULL,
    [voicemail_short_url]       NVARCHAR(4000)  NULL,
    [country_code_a2]           NVARCHAR(4000)  NULL,
    [pricing_type]              NVARCHAR(4000)  NULL,
    [ivr_options_selected_json] NVARCHAR(MAX)   NULL,
    [create_ts]                 DATETIME2       NULL
);
END ;