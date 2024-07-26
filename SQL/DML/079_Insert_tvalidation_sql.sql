--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Metal Validation - Account - Duplicates' AS validation_sql_desc ,
       'select count(*) from (
select policynumber 
from edw_stage.account where PolicyNumber is not null
group by policynumber
having count(*)>1 ) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - stage is pending cancel' AS validation_sql_desc ,
       'select count(*) from (
select * from edw_stage.AccountTransaction 
where state=''ISSUED'' and stage=''PENDINGCANCEL''
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Issued transaction with prorated premium' AS validation_sql_desc ,
       'select count(*) from (
select PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,IssuedDate
from edw_stage.AccountTransaction a, edw_stage.Product b 
where 
state=''ISSUED'' and stage=''POLICY'' and NetPremiumDeltaProRated is not null 
and a.ProductId=b.id and ProductLine=''PersonalLines''
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Duplicates' AS validation_sql_desc ,
       'select count(*) from (
select PolicyNumber,EffectiveDate,PolicyChangeNumber
from edw_stage.AccountTransaction 
where state=''ISSUED''
group by PolicyNumber,EffectiveDate,PolicyChangeNumber
having count(*)>1) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Duplicate EffectiveDate' AS validation_sql_desc ,
       'select count(*) from (
select policynumber from 
(
select distinct PolicyNumber,EffectiveDate
from edw_stage.AccountTransaction 
where state=''ISSUED''
group by PolicyNumber,EffectiveDate,PolicyChangeNumber
having count(*)>1
)a
group by PolicyNumber
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Insured - Duplicates' AS validation_sql_desc ,
       'select count(*) from (
select referencecode from edw_stage.Insured
where ReferenceCode!=0
group by ReferenceCode
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - BillingAccount - Duplicates' AS validation_sql_desc ,
       'select count(*) from (
select referencecode from edw_stage.BillingAccount
group by ReferenceCode
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Duplicate transactions' AS validation_sql_desc ,
       'select count(*) from (
select PolicyNumber,EffectiveDate,Number from edw_stage.AccountTransaction 
where PolicyNumber is not null and [stage] in (''POLICY'',''QUOTE'')
GROUP BY PolicyNumber,EffectiveDate,Number
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Insured - Missing insured' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionversion a 
where not exists (select * from edw_stage.insured b where a.PrimaryInsuredId=b.id)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Insured - Missing insured' AS validation_sql_desc ,
       'select count(*) from (
select acct.Id ,acct.PolicyNumber
		FROM edw_stage.AccountTransaction acct   
		left JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id  
		WHERE acct.Stage in (''QUOTE'',''POLICY'')
		and	acctv.id is null
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionVersionObjectField - Bad data like value' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountTransactionVersionObjectField where value=''#VALUE!'' or  [value]=''NaN'' or value like ''%N/A%''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountobjectField - Bad data like value or NaN' AS validation_sql_desc ,
       'select count(*) from edw_stage.AccountobjectField where [value]=''#VALUE!'' or [value]=''NaN''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionVersionObject - Collections - Missing class type data' AS validation_sql_desc ,
       'select count(*) from (
select a.PolicyNumber from edw_stage.AccountTransaction a, edw_stage.AccountTransactionVersion b, edw_stage.product c
where a.id=b.AccountTransactionId and a.ProductId=c.id and c.ProductCode=''LUX''
and a.[State]=''ISSUED'' and not exists (Select * from edw_stage.AccountTransactionVersionObject d where b.id=d.AccountTransactionVersionId and ObjectType=''CollectionClass'')
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - IssuedDate is null' AS validation_sql_desc ,
       'select count(*) from (
select id,PolicyNumber,EffectiveDate,Stage,[State],IssuedDate,BindDate,NetPremiumDeltaProRated 
from edw_stage.AccountTransaction 
where STATE=''ISSUED'' and issueddate is null and PolicyNumber is not null
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;