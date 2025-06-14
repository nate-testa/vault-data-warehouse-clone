INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
    'Snapsheet claims - null product_sk' AS validation_sql_desc ,
    'select count(*) from edw_core.tclaim where source_system_sk = 5 and product_sk is null' AS source_sql ,
    'select 0' AS target_sql ,
    'Y' AS active_in ,
    'Daily' AS frequency_desc ,
    getdate() AS create_ts ,
    getdate() AS update_ts; 