IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'majesco_installment_data_feed')
BEGIN

CREATE TABLE [edw_stage].[majesco_installment_data_feed](
	[policy_no] [varchar](50) NULL,
	[account_no] [bigint] NULL,
	[system_activity_no] [varchar](50) NULL,
	[system_transaction_seq] [bigint] NULL,
	[receivable_item_seq] [bigint] NULL,
	[bill_no] [bigint] NULL,
	[receivable_code] [varchar](50) NULL,
	[bill_to_entity] [bigint] NULL,
	[commission_amount] [decimal](18, 2) NULL,
	[system_remarks] [varchar](500) NULL,
	[user_remarks] [varchar](500) NULL,
	[receivable_level] [varchar](50) NULL,
	[transaction_type] [varchar](50) NULL,
	[gross_amount] [decimal](18, 2) NULL,
	[net_amount] [decimal](18, 2) NULL,
	[bill_to_entity_type] [varchar](50) NULL,
	[bill_type] [varchar](50) NULL,
	[bill_gross_net] [varchar](50) NULL,
	[created_by] [varchar](100) NULL,
	[created_on] [datetime] NULL,
	[accounting_year_month] [int] NULL,
	[receivable_category] [varchar](50) NULL,
	[downpay_yn] [char](1) NULL,
	[commission_percent] [decimal](18, 2) NULL,
	[amount_spread_option] [varchar](50) NULL,
	[bill_activity_date] [datetime] NULL,
	[bill_date_prepared] [datetime] NULL,
	[cancel_check_processed_date] [datetime] NULL,
	[original_due_date] [datetime] NULL,
	[direct_bill_send_date] [datetime] NULL,
	[direct_bill_due_date] [datetime] NULL,
	[bill_send_date] [datetime] NULL,
	[bill_due_date] [datetime] NULL,
	[installment_no] [int] NULL,
	[billvoided_yn] [char](1) NULL,
	[voided_date] [datetime] NULL,
	[source_system_sk] [int] NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL
) ON [PRIMARY]

end
