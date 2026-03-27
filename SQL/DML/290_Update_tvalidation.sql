-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 40'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

-- 25 tpolicy_transaction - policies having vehicle_coverage_sk = 0 for AU
update edw_core.tvalidation_sql 
set target_sql = 'select 1'
where validation_sql_desc= 'tpolicy_transaction - policies having vehicle_coverage_sk = 0 for AU' 

-- 44  tpolicy_transaction - LUX - collection_class_type_sk = 0
update edw_core.tvalidation_sql 
set target_sql = 'select 2'
where validation_sql_desc= 'tpolicy_transaction - LUX - collection_class_type_sk = 0'