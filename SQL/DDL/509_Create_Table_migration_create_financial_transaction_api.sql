IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_financial_transaction_api')
BEGIN

CREATE TABLE [edw_stage].[migration_create_financial_transaction_api](
	[financial_transaction_id] [int] IDENTITY(1,1) NOT NULL,
	[claim_no] [varchar](255) ,
	[data] [nvarchar](max) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[api_status] [varchar](255) ,
	[api_error_description] [varchar](2000) ,
	[Id] [int] ,
	[api_response] [nvarchar](max) ,
	[POST_DATE] [datetime] ,
	[ITEM_ID] [decimal](19, 0) ,
	[reserve_type] [varchar](255) ,
	[remote_identifier] [decimal](19, 0) ,
	[HIS_ID] [decimal](19, 0) ,
	[amount_type] [varchar](255) NULL
)
END