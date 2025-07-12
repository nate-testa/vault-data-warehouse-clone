INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tbroker - null commercial_or_personal_business_type' AS validation_sql_desc ,
       'select count(*) from edw_core.tbroker where commercial_or_personal_business_type is null' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;