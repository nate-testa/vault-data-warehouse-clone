INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tclaim_trasnaction - missing claim payment transaction' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_payment a where 
not exists (select * from edw_core.tclaim_transaction b where a.claim_payment_sk=b.claim_payment_sk) and payment_status in (''issued'',''submitted'',''cleared'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tclaim_feature - aslob_sk is null but claim coverage exists' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_feature a where aslob_sk is null and source_system_sk!=1 and claim_coverage_desc is not null' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tclaim_feature - claim_coverage_desc is null' AS validation_sql_desc ,
       'select count(*) from edw_core.tclaim_feature a where claim_coverage_desc is null and source_system_sk!=1' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;