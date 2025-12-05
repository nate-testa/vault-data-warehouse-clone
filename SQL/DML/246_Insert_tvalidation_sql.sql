INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tproducer - Duplicate email for Active and pending producer' ,
'select count(*) from edw_core.tproducer  a  
where exists (select  email from edw_core.tproducer b where   a.email = b.email group by email having count(*) > 1 )
and email in (select email from edw_core.tproducer where producer_status = ''Active'' )
and email in (select email from edw_core.tproducer where producer_status = ''Pending'' )'  AS source_sql ,
       'select  0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;