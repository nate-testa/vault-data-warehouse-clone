IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'int_claims_payments_audit')
BEGIN
CREATE TABLE [edw_stage].[int_claims_payments_audit](
	[id] [int] ,
	[uuid] [nvarchar](255) ,
	[pm_cr_payment_id] [nvarchar](255) ,
	[pm_ip_payment_id] [nvarchar](255) ,
	[pm_amount] [decimal](10, 2) ,
	[pm_funded] [bit] ,
	[pm_status] [nvarchar](255) ,
	[pm_paid_date] [datetime2](0) ,
	[pm_cleared_date] [datetime2](0) ,
	[pm_escheat_date] [datetime2](0) ,
	[pm_check_print_date] [datetime2](0) ,
	[pm_check_number] [nvarchar](255) ,
	[pm_mail_tracking_number] [nvarchar](100) ,
	[pm_method_id] [nvarchar](255) ,
	[pm_monitored] [nvarchar](1) ,
	[pm_reject_payee_id] [nvarchar](255) ,
	[pm_reject_reason] [nvarchar](max) ,
	[pm_new_method] [nvarchar](255) ,
	[pm_orig_method] [nvarchar](255) ,
	[pm_selection] [nvarchar](100) ,
	[pm_method_last4digit] [nvarchar](40) ,
	[pm_re_issue] [nvarchar](1) ,
	[pm_error_code] [nvarchar](50) ,
	[pm_error_message] [nvarchar](max) ,
	[pm_carrier_id] [nvarchar](255) ,
	[pm_env] [nvarchar](255) ,
	[request_json] [nvarchar](max) ,
	[created_by] [nvarchar](255) ,
	[created_date] [nvarchar](255) 
) 
END ; 