update edw_core.tvalidation_sql
set target_sql = 'select 1'
where
	validation_sql_desc = 'tclaim_transaction - missing claim payment transaction'
 
update edw_core.tvalidation_sql
set target_sql = 'select 1'
where
	validation_sql_desc = 'tclaim_feature - aslob_sk is null but claim coverage exists'
 
update edw_core.tvalidation_sql
set target_sql = 'select 3'
where
	validation_sql_desc = 'tclaim_transaction - feature_status_sk null'
 
update edw_core.tvalidation_sql
set target_sql = 'select 0'
where
	validation_sql_desc = 'tbroker - null commercial_or_personal_business_type'