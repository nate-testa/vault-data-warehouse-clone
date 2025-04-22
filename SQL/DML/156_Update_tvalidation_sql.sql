update edw_core.tvalidation_sql
set 
source_sql='select count(*) from edw_stage_snapsheet.financial_transactions where stage=''cancelled'' and approved_at is not null and remote_identifier is null',
target_sql = 'select 2'
where validation_sql_desc = 'Snapsheet Validation- Cancelled approved reserves/payments';