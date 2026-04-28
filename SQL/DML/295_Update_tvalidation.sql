  -- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 51'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'


-- 84 tclaim_feature - claim_coverage_desc is null
update edw_core.tvalidation_sql 
set target_sql = 'select 3'
where validation_sql_desc= 'tclaim_feature - claim_coverage_desc is null'


-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 16'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'

-- 81 Snapsheet Validation- Cancelled approved reserves/payments
set source_sql='select count(*) 
from edw_stage_snapsheet.financial_transactions 
where stage=''cancelled'' 
and approved_at is not null 
and remote_identifier is null 
and financial_transaction_type != ''recovery'''
,target_sql='select 4',
validation_sql_desc='Snapsheet Validation- Cancelled approved reserves/payments'
where validation_sql_desc='Snapsheet Validation- Cancelled approved reserves/payments'