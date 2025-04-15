if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_policy_level_monthly_commission_balance')
begin
create table edw_stage.stage_majesco_policy_level_monthly_commission_balance(
accounting_month	varchar(255) null, 
policy_no	varchar(255) null, 
policy_term_id	varchar(255) null, 
policy_renew_no	varchar(255) null, 
policy_effective_date	varchar(255) null, 
commission_entity_name	varchar(255) null, 
commission_entity_type	varchar(255) null, 
commission_entity_code	varchar(255) null, 
commission_payee_entity_type	varchar(255) null, 
commission_payee_entity_code	varchar(255) null, 
commission_statement_entity_type	varchar(255) null, 
commission_statement_entity_code	varchar(255) null, 
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
bill_type	varchar(255) null, 
commission_basis	varchar(255) null, 
receivable_code	varchar(255) null, 
receivable_category	varchar(255) null, 
premium_amount	varchar(255) null, 
commission_percentage	varchar(255) null, 
total_commission_to_be_paid	varchar(255) null, 
commission_adjustment	varchar(255) null, 
commission_paid	varchar(255) null, 
commission_balance_payable	varchar(255) null, 
begining_balance	varchar(255) null, 
ending_balance	varchar(255) null, 
month	varchar(255) null, 
create_ts	datetime null
)
end ;