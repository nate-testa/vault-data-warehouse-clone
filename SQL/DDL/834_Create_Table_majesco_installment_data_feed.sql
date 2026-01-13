IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'stage_majesco_installment_data_feed')
BEGIN

CREATE TABLE [edw_stage].[stage_majesco_installment_data_feed](
	[policy_no] [varchar](255) NULL,
	[account_no] [varchar](255) NULL,
	[system_activity_no] [varchar](255) NULL,
	[system_transaction_seq] [varchar](255) NULL,
	[receivable_item_seq] [varchar](255) NULL,
	[bill_no] [varchar](255) NULL,
	[receivable_code] [varchar](255) NULL,
	[bill_to_entity] [varchar](255) NULL,
	[commission_amount] [varchar](255) NULL,
	[system_remarks] [varchar](255) NULL,
	[user_remarks] [varchar](255) NULL,
	[receivable_level] [varchar](255) NULL,
	[transaction_type] [varchar](255) NULL,
	[gross_amount] [varchar](255) NULL,
	[net_amount] [varchar](255) NULL,
	[bill_to_entity_type] [varchar](255) NULL,
	[bill_type] [varchar](255) NULL,
	[bill_gross_net] [varchar](255) NULL,
	[created_by] [varchar](255) NULL,
	[created_on] [varchar](255) NULL,
	[accounting_year_month] [varchar](255) NULL,
	[receivable_category] [varchar](255) NULL,
	[downpay_yn] [varchar](255) NULL,
	[commission_percent] [varchar](255) NULL,
	[amount_spread_option] [varchar](255) NULL,
	[bill_activity_date] [varchar](255) NULL,
	[bill_date_prepared] [varchar](255) NULL,
	[cancel_check_processed_date] [varchar](255) NULL,
	[original_due_date] [varchar](255) NULL,
	[direct_bill_send_date] [varchar](255) NULL,
	[direct_bill_due_date] [varchar](255) NULL,
	[bill_send_date] [varchar](255) NULL,
	[bill_due_date] [varchar](255) NULL,
	[installment_no] [varchar](255) NULL,
	[billvoided_yn] [varchar](255) NULL,
	[voided_date] [varchar](255) NULL,
	[start_date] [varchar](255) NULL,
	[end_date] [varchar](255) NULL,
	[create_ts] [datetime] NULL
) ON [PRIMARY]

end
