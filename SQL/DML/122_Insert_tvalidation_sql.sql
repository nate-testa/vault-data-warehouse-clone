INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Snapsheet Validation- Cancelled Reserves' AS validation_sql_desc ,
       'select count(*) from edw_stage_snapsheet.financial_transactions a where not exists (select * from edw_stage_snapsheet.financial_payment_items b
where a.id=b.financial_transaction_id) and stage=''cancelled''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;


       