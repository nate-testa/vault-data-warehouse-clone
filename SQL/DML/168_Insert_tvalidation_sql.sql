INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tproducer - Duplicate producer email' AS validation_sql_desc ,
       'select count(*) from edw_core.tproducer  
where email + broker_id in (select  email + broker_id from edw_integration.producer_hubspot_feed group by email, broker_id having count(*) > 1)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts; 