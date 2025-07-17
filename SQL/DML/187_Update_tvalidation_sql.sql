update edw_core.tvalidation_sql 
set target_sql = 'select 0', update_ts = GETDATE()
where validation_sql_desc = 'tclaim_transaction - total reserves <> 0 for closed claim' ; 

update edw_core.tvalidation_sql 
set target_sql = 'select 6', update_ts = GETDATE()
where validation_sql_desc = 'Snapsheet Validation- Cancelled approved reserves/payments' ; 
