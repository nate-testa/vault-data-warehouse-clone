INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Metal Validation - AccountTransaction - Bound Transactions' AS validation_sql_desc ,
       'SELECT count(*) FROM edw_stage.accounttransaction a, edw_stage.Product c
where a.ProductId=c.id and c.ProductLine=''PersonalLines'' and a.Stage=''POLICY''
and a.[State]=''BOUND''
and datediff(day,cast(a.BindDate as date),cast(getdate() as date)) >15' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Metal Validation - AccountTransaction - Missing premium stat records for issued transactions' AS validation_sql_desc ,
       'select count(*) from edw_stage.accounttransaction a, edw_stage.Product b
where not exists (select * from edw_stage.AccountTransactionCoveragePremium b
where a.id=b.AccountTransactionId) and a.[State]=''ISSUED'' and a.ProductId=b.id and b.ProductLine=''PersonalLines''
and cast(IssuedDate as date)>=''20240301''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Metal Validation - AccountTransaction - Bound transactions for Non NY states' AS validation_sql_desc ,
       'SELECT count(*) FROM edw_stage.accounttransaction a, edw_stage.AccountTransactionVersion b, edw_stage.Product c
  		where b.AccountTransactionId=a.id and a.ProductId=c.id and c.ProductLine=''PersonalLines''
  		and a.[State]=''BOUND''  and b.RiskStateCode!=''NY''  
		' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts; 