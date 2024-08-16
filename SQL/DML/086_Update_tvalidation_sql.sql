update edw_core.tvalidation_sql set target_sql = 'select 2'
where validation_sql_desc = 'tcatastrophe - alpha characters in CAT code'

update edw_core.tvalidation_sql set target_sql = 'select 110'
where validation_sql_desc = 'tpolicy_transaction - negative total prmeium_amt'

update edw_core.tvalidation_sql set target_sql = 'select 6'
where validation_sql_desc = 'tclaim_transaction - total reserves <> 0 for closed claim'

update edw_core.tvalidation_sql set target_sql = 'select 2'
where validation_sql_desc = 'Metal Validation - AccountTransaction - Issued transaction with prorated premium'

update edw_core.tvalidation_sql set target_sql = 'select 1'
where validation_sql_desc = 'Metal Validation - AccountTransactionVersionObject - Collections - Missing class type data'