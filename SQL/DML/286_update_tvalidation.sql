-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 39'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 12'
where
	validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'

-- 120 Current Carrier PR01- Missing required fields
update edw_core.tvalidation_sql 
set target_sql = 'select 1'
where
	validation_sql_desc= 'Current Carrier  PR01- Missing required fields'

-- 124 Current Carrier VR01- Missing required fields
update edw_core.tvalidation_sql 
set target_sql = 'select 1'
where
	validation_sql_desc= 'Current Carrier VR01- Missing required fields'

-- 112 Broker - Brokers with policies or quotes in both commercial and personal lines
update edw_core.tvalidation_sql 
set target_sql = 'select 2'
where
	validation_sql_desc= 'Broker - Brokers with policies or quotes in both commercial and personal lines'
	