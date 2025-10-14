INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'New state in hubspot customer feed' ,
'select  count(distinct mailing_address_state_cd) from edw_integration.customer_hubspot_feed
where mailing_address_state_cd not in ( select state_cd from edw_core.tstate)
and   mailing_address_state_cd not in (''BC'',''England'',''London'',''NSW'',''ON'',''PR'',''QC'')
and update_ts >= DATEADD(day, -2, getdaTE())' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;