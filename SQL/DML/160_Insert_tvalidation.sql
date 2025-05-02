INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tclaim_transaction - row count is 0' AS validation_sql_desc ,
       'select count(*) from edw_core.tetl_audit where process_nm=''sp_tclaim_transaction_snapsheet'' and 
DATENAME(WEEKDAY, process_start_ts) not in (''Monday'',''Sunday'') and record_ct=0 and cast(process_start_ts as date)=cast(getdate() as date)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tpolicy_transaction - row count is 0' AS validation_sql_desc ,
       'select count(*) from edw_core.tetl_audit where process_nm=''sp_tpolicy_transaction'' and 
DATENAME(WEEKDAY, process_start_ts) not in (''Monday'',''Sunday'') and record_ct=0 and cast(process_start_ts as date)=cast(getdate() as date)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;