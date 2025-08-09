INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Inforce customers with $0 inforce premium' ,
       'select count(*) from edw_core.tdaily_inforce_policy where inforce_dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'') group by customer_sk having sum(premium_amt) = 0' AS source_sql ,
       'select 1' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;