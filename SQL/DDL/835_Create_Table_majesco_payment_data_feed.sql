IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'majesco_payment_data_feed')
BEGIN

CREATE TABLE [edw_stage].[majesco_payment_data_feed](
	[policy_no] [varchar](50) NULL,
	[account_no] [bigint] NULL,
	[system_activity_no] [varchar](50) NULL,
	[system_transaction_seq] [bigint] NULL,
	[receivable_item_seq] [bigint] NULL,
	[transaction_type] [varchar](50) NULL,
	[payment_amount] [decimal](18, 2) NULL,
	[created_on] [datetime] NULL,
	[created_by] [varchar](100) NULL,
	[system_remark] [varchar](500) NULL,
	[user_remark] [varchar](500) NULL,
	[accounting_year_month] [int] NULL,
	[bill_type] [varchar](50) NULL,
	[underwriting_company] [varchar](50) NULL,
	[operating_company] [varchar](50) NULL,
	[payment_method] [varchar](50) NULL,
	[payment_channel] [varchar](50) NULL,
	[data_segment] [varchar](50) NULL,
	[source_system_sk] [int] NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL
) ON [PRIMARY]

end
