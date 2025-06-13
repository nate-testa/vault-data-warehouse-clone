INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Clearinghouse fee transactions mapped to incorrect coverage category ' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionTaxAndFee where [name]=''Clearinghouse fee'' and Type = ''Fee''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'EMPA Surcharge transactions mapped to incorrect coverage category' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionTaxAndFee where [name]=''EMPA Surcharge'' and Type = ''Surcharge''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'Surplus Lines Tax transactions mapped to incorrect coverage category ' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionTaxAndFee where [name]=''Surplus Lines Tax'' and Type = ''Tax''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'Healthy Homes Fund Surcharge transactions mapped to incorrect coverage category ' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionTaxAndFee where [name]=''Healthy Homes Fund Surcharge'' and Type = ''Surcharge''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;