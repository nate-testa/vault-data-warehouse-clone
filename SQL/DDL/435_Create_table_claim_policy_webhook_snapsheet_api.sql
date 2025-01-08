CREATE TABLE [edw_integration].[claim_policy_webhook_snapsheet_api]
(
    [cancelledAt] [datetime] NULL,
	[cancelledReason] [varchar](2000) NULL,
	[effectiveAt] [datetime] NOT NULL,
	[expirationAt] [datetime] NOT NULL,
	[inceptionAt] [datetime] NOT NULL,
	[policyNumber] [varchar](200) NOT NULL,
	[policyType] [varchar](255) NOT NULL,
	[status] [varchar](255) NOT NULL,
	[version] [datetime] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[agentInformation] [nvarchar](2000) NULL,
	[product] [nvarchar](2000) NOT NULL,
	[reservation] [nvarchar](2000) NULL,
	[underwriting] [nvarchar](2000) NULL,
	[coverages] [nvarchar](2000) NULL,
	[endorsements] [nvarchar](2000) NULL,
	[notes] [nvarchar](2000) NULL,
	[businesses] [nvarchar](max) NULL,
	[people] [nvarchar](max) NULL,
	[risks] [nvarchar](max) NULL,
	[versions] [nvarchar](2000) NULL,
	[deductibles] [nvarchar](2000) NULL,
	[source_system_nm] [varchar](255) NOT NULL,
	[data] [nvarchar](max) NULL,
	[create_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
      CONSTRAINT uidx_claim_policy_webhook_snapsheet_api UNIQUE (policyNumber, effectiveAt, transaction_seq_no)
); 
 
INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts)
    VALUES ('claim_policy_webhook_snapsheet_api','API','This table provides policy coverage details as of loss date to support Snapsheet policy Webhook API','Stored Procedure','Insert','Daily',getdate(),getdate());
