-- 84 tclaim_feature - claim_coverage_desc is null
update edw_core.tvalidation_sql 
set target_sql = 'select 2'
where
	validation_sql_desc= 'tclaim_feature - claim_coverage_desc is null'

-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 8'
where
	validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'

-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 33'
where
	validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

-- 81 Snapsheet Validation- Cancelled approved reserves/payments
update edw_core.tvalidation_sql 
set target_sql = 'select 9'
where
	validation_sql_desc= 'Snapsheet Validation- Cancelled approved reserves/payments'