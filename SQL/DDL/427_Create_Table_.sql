CREATE TABLE [edw_integration].[create_policy_search_snapsheet_api]
(
	[policyNumber] [varchar](255) NOT NULL,
	[policyType] [varchar](255) NOT NULL,
	[status] [varchar](255) NOT NULL,
	[productCode] [varchar](255) NOT NULL,
	[policyEntities] [nvarchar](max),
    [inceptionDate] [date] NOT NULL,
	[expiration_dt] [date] NOT NULL,
	[transaction_effective_dt] [date] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[transaction_type] [varchar](255) NOT NULL,
	[source_system_nm] [varchar](255) NOT NULL,
	[api_status] [varchar](255) NULL,
	[api_error_description] [varchar](max) NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
    CONSTRAINT uidx_create_policy_search_snapsheet_api UNIQUE (policyNumber, inceptionDate, transaction_seq_no)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('create_policy_search_snapsheet_api','API','This table provides policy details for claims registration purpose to support Snapsheet create policy API','Stored Procedure','Insert','Daily',getdate(),getdate());