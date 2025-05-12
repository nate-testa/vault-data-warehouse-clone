IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_update_exposure_adjuster_api')
BEGIN

CREATE TABLE [edw_stage].[migration_update_exposure_adjuster_api](
	[claim_no] [varchar](255) NOT NULL,
	[exposure_id] [varchar](255) NOT NULL,
	[adjuster_nm] [varchar](255) ,
	[exposureReferenceNumber] [varchar](255) NOT NULL,
	[externalReferenceNumber] [varchar](255) NOT NULL,
	[snapsheet_adjuster_id] [varchar](255) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[api_status] [varchar](255) ,
	[api_Error_description] [varchar](2000) ,
	[api_response] [nvarchar](max) ,
	[data] [nvarchar](max) 
)
END