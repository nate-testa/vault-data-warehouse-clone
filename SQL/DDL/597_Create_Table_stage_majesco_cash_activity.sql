if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_cash_activity')
begin
create table edw_stage.stage_majesco_cash_activity(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
agency_code	varchar(255) null, 
agency_name	varchar(255) null, 
account_code	varchar(255) null, 
account_name	varchar(255) null, 
policy_no	varchar(255) null, 
line_of_business	varchar(255) null, 
company_batch_no	varchar(255) null, 
policy_effective_date	varchar(255) null, 
entry_date	varchar(255) null, 
accounting_month	varchar(255) null, 
receivable_category	varchar(255) null, 
receivable_code	varchar(255) null, 
receivable_type	varchar(255) null, 
pay_type	varchar(255) null, 
payment_identifier	varchar(255) null, 
batch_no	varchar(255) null, 
check_serial_no	varchar(255) null, 
transaction_no	varchar(255) null, 
amount	varchar(255) null, 
transaction_type	varchar(255) null, 
bill_type	varchar(255) null, 
operating_region_code	varchar(255) null, 
operating_region	varchar(255) null, 
crt_code	varchar(255) null, 
state	varchar(255) null, 
payment_plan	varchar(255) null, 
user_id	varchar(255) null, 
bill_type_description	varchar(255) null, 
start_date	varchar(255) null, 
end_date	varchar(255) null, 
create_ts	datetime null
)
end ; 
