IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'stage_majesco_payment_data_feed')
BEGIN

CREATE TABLE [edw_stage].[stage_majesco_payment_data_feed](
	[policy_no] [varchar](255) NULL,
	[account_no] [varchar](255) NULL,
	[system_activity_no] [varchar](255) NULL,
	[system_transaction_seq] [varchar](255) NULL,
	[receivable_item_seq] [varchar](255) NULL,
	[transaction_type] [varchar](255) NULL,
	[payment_amount] [varchar](255) NULL,
	[created_on] [varchar](255) NULL,
	[created_by] [varchar](255) NULL,
	[system_remark] [varchar](255) NULL,
	[user_remark] [varchar](255) NULL,
	[accounting_year_month] [varchar](255) NULL,
	[bill_type] [varchar](255) NULL,
	[underwriting_company] [varchar](255) NULL,
	[operating_company] [varchar](255) NULL,
	[payment_method] [varchar](255) NULL,
	[payment_channel] [varchar](255) NULL,
	[data_segment] [varchar](255) NULL,
	[start_date] [varchar](255) NULL,
	[end_date] [varchar](255) NULL,
	[create_ts] [datetime] NULL
) ON [PRIMARY]

end
