--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal Validation - AccountTransaction - Duplicate cancelled transactions ' AS validation_sql_desc ,
       'select count(*) from (
select PolicyNumber,EffectiveDate,Cast(IssuedDate as date) issueddate
from edw_stage.AccountTransaction a
where state=''ISSUED'' and stage=''CANCELLATION''
and not exists (select * from edw_stage.accounttransaction b where a.policynumber=b.PolicyNumber and b.state=''ISSUED'' and STAGE=''REINSTATEMENT'')
group by PolicyNumber,EffectiveDate,Cast(IssuedDate as date)
having count(*)>1) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - policies in bound status for more than 15 days' AS validation_sql_desc ,
       'SELECT count(*)
FROM edw_stage.accounttransaction a, edw_stage.Product c
where a.ProductId=c.id and c.ProductLine=''PersonalLines''
and a.Stage=''POLICY'' and a.[State]=''BOUND''
and datediff(day,cast(a.EffectiveDate as date),cast(getdate() as date)) >15' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

--
UPDATE edw_core.tvalidation_sql
SET validation_sql_desc = 'Metal Validation - AccountTransactionVersion - Missing records'
WHERE validation_sql_desc = 'Metal Validation - Insured - Missing insured'
AND source_sql like '%acctv%';