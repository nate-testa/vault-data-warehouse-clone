-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 6'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'


  -- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 48'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

--123 Current Carrier SJ01- Policies having no A1 record  

update edw_core.tvalidation_sql 
set target_sql = 'select 2'
where validation_sql_desc= 'Current Carrier SJ01- Policies having no A1 record'
