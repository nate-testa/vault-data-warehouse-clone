if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_adjust_writeoff')
begin
create table edw_stage.stage_majesco_adjust_writeoff(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
operating_region_code	varchar(255) null, 
operating_region	varchar(255) null, 
agency_code	varchar(255) null, 
agency_name	varchar(255) null, 
account_code	varchar(255) null, 
policy_no	varchar(255) null, 
policy_eff_date	varchar(255) null, 
bill_type	varchar(255) null, 
bill_type_description	varchar(255) null, 
transaction_no	varchar(255) null, 
transaction_code	varchar(255) null, 
writeoff_transaction_type	varchar(255) null, 
write_off_reason_code	varchar(255) null, 
reason_description	varchar(255) null, 
transaction_receivable_type	varchar(255) null, 
gross_amount	varchar(255) null, 
net_amount	varchar(255) null, 
commission_amount	varchar(255) null, 
entry_date	varchar(255) null, 
accounting_month	varchar(255) null, 
adj_writeoff_type	varchar(255) null, 
state_name	varchar(255) null, 
product_name	varchar(255) null, 
payment_plan	varchar(255) null, 
crt_name	varchar(255) null, 
policy_term_id	varchar(255) null, 
line_of_business	varchar(255) null, 
user_id	varchar(255) null, 
receivable_code	varchar(255) null, 
start_date	varchar(255) null, 
end_date	varchar(255) null, 
create_ts	datetime null
)
end ; 
