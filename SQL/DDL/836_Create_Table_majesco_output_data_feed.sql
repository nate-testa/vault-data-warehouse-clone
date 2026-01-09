IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'majesco_output_data_feed')
BEGIN

CREATE TABLE [edw_stage].[majesco_output_data_feed](
	[policy_no] [varchar](50) NULL,
	[account_no] [bigint] NULL,
	[system_activity_no] [varchar](50) NULL,
	[system_transaction_seq] [bigint] NULL,
	[underwriting_company] [varchar](50) NULL,
	[policy_eff_date] [datetime] NULL,
	[policy_exp_date] [datetime] NULL,
	[product_code] [varchar](50) NULL,
	[state_code] [varchar](10) NULL,
	[form_name] [varchar](100) NULL,
	[form_description] [varchar](255) NULL,
	[receipient_type] [varchar](50) NULL,
	[date_generate] [datetime] NULL,
	[doc_id] [varchar](100) NULL,
	[mailing_entity_type] [varchar](50) NULL,
	[mailing_entity_system_code] [varchar](50) NULL,
	[source_system_sk] [int] NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL
) ON [PRIMARY]

end
