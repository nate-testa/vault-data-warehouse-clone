INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal EDW Validation - AccountTransactionTaxAndFee (name=Clearinghouse fee and Type = Fee) - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransactionTaxAndFee where [name]=''Clearinghouse fee'' and Type = ''Fee''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'Metal EDW Validation - AccountTransactionTaxAndFee (name=EMPA Surcharge and Type = Surcharge) - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransactionTaxAndFee where [name]=''EMPA Surcharge'' and Type = ''Surcharge''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'Metal EDW Validation - AccountTransactionTaxAndFee (name=Surplus Lines Tax and Type = Tax) - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransactionTaxAndFee where [name]=''Surplus Lines Tax'' and Type = ''Tax''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
	'Metal EDW Validation - AccountTransactionTaxAndFee (name=Healthy Homes Fund Surcharge and Type = Surcharge) - Compare rows between Metal and EDW stage ' AS validation_sql_desc ,
       'select count(*) from dbo.AccountTransactionTaxAndFee where [name]=''Healthy Homes Fund Surcharge'' and Type = ''Surcharge''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;