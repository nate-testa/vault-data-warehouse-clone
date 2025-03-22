INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tclaim_feature snapsheet claims - missing item_sk' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_feature a where item_sk is null and source_system_sk=5' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts

union

SELECT
'tclaim_feature snapsheet claims - missing coverage_sk' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_feature a where coverage_sk is null and source_system_sk=5' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts

union

SELECT
'tclaim_feature snapsheet claims - missing vehicle_coverage_sk' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_feature a where coverage_sk is null and source_system_sk=5 and product_sk = 3' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts