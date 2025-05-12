IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_claim_api')
BEGIN
CREATE TABLE [edw_stage].[migration_create_claim_api](
	[claimNumber] [varchar](255) NOT NULL,
	[claimType] [varchar](255) ,
	[status] [varchar](255) ,
	[policyNumber] [varchar](255) ,
	[firstOpenedAt] [datetime] ,
	[firstClosedAt] [datetime] ,
	[openedAt] [datetime] ,
	[closedAt] [datetime] ,
	[datetimeOfLoss] [datetime] ,
	[datetimeOfNotification] [datetime] ,
	[fraudScore] [int] ,
	[fraudLevelIndicator] [nvarchar](2000) ,
	[providerCode] [varchar](255) ,
	[coverageCheck] [nvarchar](2000) ,
	[accountCode] [varchar](255) ,
	[lossType] [varchar](255) ,
	[notes] [nvarchar](max) ,
	[reservation] [nvarchar](max) ,
	[claimIncidentDetails] [nvarchar](max) ,
	[emergencyServicesDetail] [nvarchar](max) ,
	[notifier] [nvarchar](2000) ,
	[notificationMethod] [varchar](255) ,
	[exposures] [nvarchar](max) ,
	[claimParties] [nvarchar](max) ,
	[vehicles] [nvarchar](max) ,
	[financialTransactions] [nvarchar](max) ,
	[create_ts] [datetime] ,
	[update_ts] [datetime] ,
	[api_status] [varchar](255) ,
	[api_Error_description] [varchar](2000) ,
	[claimReferenceNumber] [varchar](255) ,
	[api_response] [nvarchar](max) ,
	[attachments] [nvarchar](max) ,
	[accidentCode] [varchar](255) ,
 CONSTRAINT [PK_migration_create_claim_api_1] PRIMARY KEY CLUSTERED 
(
	[claimNumber] ASC
)
)

END