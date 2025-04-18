

if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_premium_activity_report')
begin
create table edw_stage.stage_majesco_premium_activity_report(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
agency_code	varchar(255) null, 
agency_name	varchar(255) null, 
producer_code	varchar(255) null, 
producer_name	varchar(255) null, 
account_code	varchar(255) null, 
policy_no	varchar(255) null, 
policy_term_id	varchar(255) null, 
policy_effective_date	varchar(255) null, 
insured_name	varchar(255) null, 
operating_region_code	varchar(255) null, 
operating_region	varchar(255) null, 
crt_code	varchar(255) null, 
crt	varchar(255) null, 
transaction_type	varchar(255) null, 
receivable_code	varchar(255) null, 
receivable_type	varchar(255) null, 
receivable_category	varchar(255) null, 
transaction_amount	varchar(255) null, 
commission_amount	varchar(255) null, 
deferred_premium	varchar(255) null, 
deferred_commission	varchar(255) null, 
transaction_process_date	varchar(255) null, 
entry_date	varchar(255) null, 
transaction_month	varchar(255) null, 
bill_type	varchar(255) null, 
bill_type_description	varchar(255) null, 
transaction_no	varchar(255) null, 
state	varchar(255) null, 
product	varchar(255) null, 
payment_plan	varchar(255) null, 
policy_renew_no	varchar(255) null, 
source_system	varchar(255) null, 
line_of_business	varchar(255) null, 
transaction_description	varchar(255) null, 
start_date	varchar(255) null, 
end_date	varchar(255) null, 
create_ts	datetime null
)
end ;