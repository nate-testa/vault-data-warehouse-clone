if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_commission_disbursement_register')
begin
create table edw_stage.stage_majesco_commission_disbursement_register(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
accounting_month	varchar(255) null, 
transaction_type	varchar(255) null, 
transaction_type_description	varchar(255) null, 
transaction_date	varchar(255) null, 
batch_no	varchar(255) null, 
check_no	varchar(255) null, 
payment_identifier	varchar(255) null, 
payment_method_code	varchar(255) null, 
payment_method	varchar(255) null, 
amount	varchar(255) null, 
payee_name	varchar(255) null, 
commission_payee_type	varchar(255) null, 
commission_payee_code	varchar(255) null, 
transaction_no	varchar(255) null, 
month	varchar(255) null, 
create_ts	datetime null
)
end ; 