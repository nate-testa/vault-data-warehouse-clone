IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_integration'
and TABLE_name = 'claim_policy_webhook_snapsheet_api')
BEGIN
CREATE TABLE [edw_integration].[claim_policy_webhook_snapsheet_api](
	[cancelledAt] [datetime] NULL,
	[cancelledReason] [varchar](2000) NULL,
	[effectiveAt] [datetime] NOT NULL,
	[expirationAt] [datetime] NOT NULL,
	[inceptionAt] [datetime] NULL,
	[policyNumber] [varchar](200) NOT NULL,
	[policyType] [varchar](255) NOT NULL,
	[status] [varchar](255) NULL,
	[version] [datetime] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[agentInformation] [nvarchar](max) NULL,
	[product] [nvarchar](max) NULL,
	[reservation] [nvarchar](max) NULL,
	[underwriting] [nvarchar](max) NULL,
	[coverages] [nvarchar](max) NULL,
	[endorsements] [nvarchar](max) NULL,
	[notes] [nvarchar](max) NULL,
	[businesses] [nvarchar](max) NULL,
	[people] [nvarchar](max) NULL,
	[risks] [nvarchar](max) NULL,
	[versions] [nvarchar](max) NULL,
	[deductibles] [nvarchar](max) NULL,
	[source_system_nm] [varchar](255) NOT NULL,
	[data] [nvarchar](max) NULL,
	[create_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
 CONSTRAINT [uidx_claim_policy_webhook_snapsheet_api] UNIQUE NONCLUSTERED 
(
	[policyNumber] ASC,
	[effectiveAt] ASC,
	[transaction_seq_no] ASC
)
)
END