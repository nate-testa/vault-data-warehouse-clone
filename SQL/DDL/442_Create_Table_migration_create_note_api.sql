CREATE TABLE [edw_stage].[migration_create_note_api](
	[claim_no] [varchar](255) NULL,
	[note_created_ts] datetime,	
	[note_json] [nvarchar](max) NULL,
	[api_status] [varchar](255) NULL,
	[api_error_description] [nvarchar](2000) NULL,
	[note_id] [varchar](255) NULL,
	[api_response] [nvarchar](max) NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL	,
	[etl_audit_sk] int NULL
)