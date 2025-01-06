IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_claim_api_update_catastrophe')
BEGIN
CREATE TABLE [edw_stage].[migration_create_claim_api_update_catastrophe](
	[claimNumber] [varchar](255) ,
	[claimRerenceNumber] [varchar](255) ,
	[accidentCode] [varchar](255) ,
	[data] [nvarchar](max) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[api_status] [varchar](255) ,
	[api_Error_description] [varchar](max) ,
	[api_response] [nvarchar](max) NULL
) 
END