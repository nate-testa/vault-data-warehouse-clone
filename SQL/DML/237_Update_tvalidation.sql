update edw_core.tvalidation_sql
set active_in= 'N', update_ts = GETDATE()
where validation_sql_desc = 'Insured name, address, city, state containing special characters' ;

update edw_core.tvalidation_sql
set target_sql = 'select 7', update_ts = GETDATE()
where validation_sql_desc = 'Snapsheet Validation- Cancelled approved reserves/payments';