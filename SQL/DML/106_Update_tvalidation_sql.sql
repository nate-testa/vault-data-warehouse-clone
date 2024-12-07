update edw_core.tvalidation_sql
set target_sql='select 0'
where validation_sql_sk=38;

update edw_core.tvalidation_sql
set validation_sql_desc='Metal Validation - AccountTransaction - Duplicate Issued transactions'
where validation_sql_sk=54;

update edw_core.tvalidation_sql
set validation_sql_desc='Metal Validation - AccountTransaction - Duplicate Quote transactions'
where validation_sql_sk=58;