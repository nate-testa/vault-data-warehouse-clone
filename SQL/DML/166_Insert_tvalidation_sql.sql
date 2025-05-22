INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal EDW Validation - AccountTransaction - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransaction where CreatedDate=''var_actual_dt''' AS source_sql ,
       'select count(*) from edw_stage.AccountTransaction where CreatedDate=''var_actual_dt''' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal EDW Validation - AccountTransactionCoveragePremium - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransactionCoveragePremium where CreatedDate=''var_actual_dt''' AS source_sql ,
       'select count(*) from edw_stage.AccountTransactionCoveragePremium where CreatedDate=''var_actual_dt''' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
