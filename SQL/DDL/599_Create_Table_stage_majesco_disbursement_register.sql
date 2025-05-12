
if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_disbursement_register')
begin
create table edw_stage.stage_majesco_disbursement_register(
operating_company_code	varchar(255) null, 
operating_company	varchar(255) null, 
underwriting_company_code	varchar(255) null, 
underwriting_company	varchar(255) null, 
policy_no	varchar(255) null, 
policy_effective_date	varchar(255) null, 
bill_type	varchar(255) null, 
bill_type_description	varchar(255) null, 
payment_identifier	varchar(255) null, 
payer_name	varchar(255) null, 
accounting_month	varchar(255) null, 
refund_void_date	varchar(255) null, 
amount	varchar(255) null, 
transaction_type	varchar(255) null, 
transaction_type_description	varchar(255) null, 
batch_no	varchar(255) null, 
check_serial_no	varchar(255) null, 
account_code	varchar(255) null, 
agency_code	varchar(255) null, 
refund_type	varchar(255) null, 
suppress_flag	varchar(255) null, 
refund_payment_method_code	varchar(255) null, 
refund_payment_method_description	varchar(255) null, 
receivable_code	varchar(255) null, 
transaction_no	varchar(255) null, 
additional_payee	varchar(255) null, 
start_date	varchar(255) null, 
end_date	varchar(255) null, 
create_ts	datetime null
)
end ; 