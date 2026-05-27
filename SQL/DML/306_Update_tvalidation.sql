   -- 84 tclaim_feature - claim_coverage_desc is null
update edw_core.tvalidation_sql 
set target_sql = 'select 1'
where validation_sql_desc= 'tclaim_feature - claim_coverage_desc is null'

  -- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 44'
where validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'


  -- 164 tpolicy_transaction - ceded premium but no gross premium
update edw_core.tvalidation_sql 
set active_in = 'N'
where validation_sql_desc= 'tpolicy_transaction - ceded premium but no gross premium'

