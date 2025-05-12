IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_integration'
and TABLE_name = 'claim_policy_search_snapsheet_api')
BEGIN
CREATE TABLE [edw_integration].[claim_policy_search_snapsheet_api](
	[policyNumber] [varchar](255) NOT NULL,
	[policyType] [varchar](255) NOT NULL,
	[status] [varchar](255) ,
	[productCode] [varchar](255) NOT NULL,
	[policyEntities] [nvarchar](max) ,
	[inceptionDate] [date] NOT NULL,
	[expiration_dt] [date] NOT NULL,
	[transaction_effective_dt] [date] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[transaction_type] [varchar](255) ,
	[source_system_nm] [varchar](255) NOT NULL,
	[api_status] [varchar](255) ,
	[api_error_description] [varchar](max) ,
	[create_ts] [datetime2](7) ,
	[update_ts] [datetime2](7) ,
	[etl_audit_sk] [int] NULL,
 CONSTRAINT [uidx_claim_policy_search_snapsheet_api] UNIQUE NONCLUSTERED 
(
	[policyNumber] ASC,
	[inceptionDate] ASC,
	[transaction_seq_no] ASC
)
)
END