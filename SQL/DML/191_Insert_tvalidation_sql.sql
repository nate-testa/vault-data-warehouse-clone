INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Broker - Brokers with policies or quotes in both commercial and personal lines' ,
       'SELECT 
    COUNT(br.broker_id)
FROM 
    edw_core.tbroker br
WHERE 
    br.broker_id IN (
        SELECT broker_id 
        FROM edw_core.tpolicy
        UNION
        SELECT broker_id 
        FROM edw_core.tquote
    )
    AND br.broker_id IN (
        SELECT broker_id 
        FROM edw_commercial.tcommercial_policy
        UNION
        SELECT broker_id 
        FROM edw_commercial.tcommercial_quote
    )' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;