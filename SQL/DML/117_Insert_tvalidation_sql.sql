/* Already deployed from staging branch on 20250125 hence commenting out for 20250207 release 

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Redzone - null lat/lon' AS validation_sql_desc ,
       'select count(*)
from edw_integration.policy_redzone_feed
where latitude is null or longitude is null' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
*/