update edw_core.tvalidation_sql
set target_sql = 'select 1'
where
	validation_sql_desc = 'tclaim_feature - aslob_sk is null but claim coverage exists'
 
update edw_core.tvalidation_sql
set target_sql = 'select 1'
where
	validation_sql_desc = 'tclaim_feature - claim_coverage_desc is null'
 
update edw_core.tvalidation_sql
set target_sql = 'select 3'
where
	validation_sql_desc = 'tclaim_feature snapsheet claims - missing coverage_sk'
 
update edw_core.tvalidation_sql
set target_sql = 'select 0'
where
	validation_sql_desc = 'Inforce customers with $0 inforce premium'