-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 43'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'