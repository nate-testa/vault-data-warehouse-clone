IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'stage_majesco_invoice_data_feed')
BEGIN

CREATE TABLE [edw_stage].[stage_majesco_invoice_data_feed](
	[policy_no] [varchar](255) NULL,
	[account_no] [varchar](255) NULL,
	[system_activity_no] [varchar](255) NULL,
	[system_transaction_seq] [varchar](255) NULL,
	[invoice_send_date] [varchar](255) NULL,
	[policy_eff_date] [varchar](255) NULL,
	[policy_exp_date] [varchar](255) NULL,
	[invoice_due_date] [varchar](255) NULL,
	[total_policy_cost] [varchar](255) NULL,
	[payment_in_full] [varchar](255) NULL,
	[current_due] [varchar](255) NULL,
	[past_due] [varchar](255) NULL,
	[installment_fee] [varchar](255) NULL,
	[nsf_fee] [varchar](255) NULL,
	[start_date] [varchar](255) NULL,
	[end_date] [varchar](255) NULL,
	[create_ts] [datetime2](7) NULL
) ON [PRIMARY]

end
