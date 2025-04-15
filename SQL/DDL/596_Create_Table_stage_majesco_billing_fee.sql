if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_billing_fee')
begin
create table edw_stage.stage_majesco_billing_fee(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
agency_code	varchar(255) null, 
agency_name	varchar(255) null, 
account_code	varchar(255) null, 
account_name	varchar(255) null, 
policy_no	varchar(255) null, 
policy_eff_date	varchar(255) null, 
fee_code	varchar(255) null, 
fee_type	varchar(255) null, 
fee_date	varchar(255) null, 
fee_month	varchar(255) null, 
fee_amount	varchar(255) null, 
bill_type	varchar(255) null, 
operating_region_code	varchar(255) null, 
operating_region	varchar(255) null, 
governing_state	varchar(255) null, 
product	varchar(255) null, 
pay_plan	varchar(255) null, 
crt_code	varchar(255) null, 
transaction_no	varchar(255) null, 
transaction_type	varchar(255) null, 
bill_type_description	varchar(255) null, 
start_date	varchar(255) null, 
end_date	varchar(255) null, 
create_ts	datetime null
)
end ; 
