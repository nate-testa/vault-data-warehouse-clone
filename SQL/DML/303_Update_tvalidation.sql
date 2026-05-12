-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 6'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'


  -- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 48'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'
