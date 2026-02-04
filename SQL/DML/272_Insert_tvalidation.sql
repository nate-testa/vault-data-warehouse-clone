INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tcustomer - null mailing state' AS validation_sql_desc ,
       'select count(*) from edw_core.tcustomer
        where mailing_address_state_cd is null and mailing_address_country_nm = ''US''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;