IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_claim_api_update_status')
BEGIN

CREATE TABLE [edw_stage].[migration_create_claim_api_update_status](
	[claim_no] [varchar](255) ,
	[id] [varchar](255) NOT NULL,
	[type] [varchar](255) ,
	[data] [nvarchar](max) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[api_status] [varchar](255) ,
	[api_Error_description] [varchar](2000) ,
	[api_response] [nvarchar](max) 
)
END