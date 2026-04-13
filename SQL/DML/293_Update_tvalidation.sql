-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 43'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

-- 84 tclaim_feature - claim_coverage_desc is null

update edw_core.tvalidation_sql 
set target_sql = 'select 3'
where validation_sql_desc= 'tclaim_feature - claim_coverage_desc is null'