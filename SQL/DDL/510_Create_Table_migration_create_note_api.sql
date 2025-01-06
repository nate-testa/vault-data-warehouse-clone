IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_note_api')
BEGIN


CREATE TABLE [edw_stage].[migration_create_note_api](
	[claim_no] [varchar](255) ,
	[note_created_ts] [datetime] ,
	[note_json] [nvarchar](max) ,
	[api_status] [varchar](255) ,
	[api_error_description] [nvarchar](2000) ,
	[note_id] [varchar](255) ,
	[api_response] [nvarchar](max) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[etl_audit_sk] [int]
)
END