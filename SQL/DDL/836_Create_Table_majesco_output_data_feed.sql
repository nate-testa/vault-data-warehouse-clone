IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'stage_majesco_output_data_feed')
BEGIN

CREATE TABLE [edw_stage].[stage_majesco_output_data_feed](
	[policy_no] [varchar](255) NULL,
	[account_no] [varchar](255) NULL,
	[system_activity_no] [varchar](255) NULL,
	[system_transaction_seq] [varchar](255) NULL,
	[underwriting_company] [varchar](255) NULL,
	[policy_eff_date] [varchar](255) NULL,
	[policy_exp_date] [varchar](255) NULL,
	[product_code] [varchar](255) NULL,
	[state_code] [varchar](255) NULL,
	[form_name] [varchar](255) NULL,
	[form_description] [varchar](255) NULL,
	[receipient_type] [varchar](255) NULL,
	[date_generate] [varchar](255) NULL,
	[doc_id] [varchar](255) NULL,
	[mailing_entity_type] [varchar](255) NULL,
	[mailing_entity_system_code] [varchar](255) NULL,
	[start_date] [varchar](255) NULL,
	[end_date] [varchar](255) NULL,
	[create_ts] [datetime] NULL
) ON [PRIMARY]

end
