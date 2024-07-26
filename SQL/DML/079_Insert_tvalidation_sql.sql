--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Metal Validation - Account - Duplicates' AS validation_sql_desc ,
       'select count(*) from (
select policynumber, count(*) 
from account where PolicyNumber is not null
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
select * from AccountTransaction 
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
from AccountTransaction a, Product b 
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
select PolicyNumber,EffectiveDate,PolicyChangeNumber,count(*) 
from AccountTransaction 
where state=''ISSUED'' -- and policynumber is not null
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
select policynumber, count(*) from 
(
select distinct PolicyNumber,EffectiveDate
from AccountTransaction 
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
select referencecode, count(*) from Insured
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
select referencecode, count(*) from BillingAccount
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
select PolicyNumber,EffectiveDate,Number,COUNT(*) from AccountTransaction 
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
       'select count(*) from AccountTransactionversion a 
where not exists (select * from insured b where a.PrimaryInsuredId=b.id)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Insured - Missing insured' AS validation_sql_desc ,
       'select count(*) from (
select acct.Id ,acct.PolicyNumber,  *
		FROM AccountTransaction acct   
		left JOIN AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id  
		WHERE acct.Stage in (''QUOTE'',''POLICY'') --- Review BOUND transactions
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
       'select count(*) from AccountTransactionVersionObjectField where value=''#VALUE!'' or  [value]=''NaN'' or value like ''%N/A%''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountobjectField - Bad data like value or NaN' AS validation_sql_desc ,
       'select count(*) from AccountobjectField where [value]=''#VALUE!'' or [value]=''NaN''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionVersionObject - Collections - Missing class type data' AS validation_sql_desc ,
       'select count(*) from (
select a.PolicyNumber from AccountTransaction a, AccountTransactionVersion b ,product c
where a.id=b.AccountTransactionId and a.ProductId=c.id and c.ProductCode=''LUX''
and a.[State]=''ISSUED'' and not exists (Select * from AccountTransactionVersionObject d where b.id=d.AccountTransactionVersionId and ObjectType=''CollectionClass'')
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - IssuedDate is null' AS validation_sql_desc ,
       'source_sql = 
select count(*) from (
select id,PolicyNumber,EffectiveDate,Stage,[State],IssuedDate,BindDate,NetPremiumDeltaProRated 
from AccountTransaction 
where STATE=''ISSUED'' and issueddate is null and PolicyNumber is not null
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Dupe primary insured - Policy' AS validation_sql_desc ,
       'select count(*) from 
(
SELECT acct.PolicyNumber, acct.EffectiveDate, acct.PolicyChangeNumber, acct.Id,acct.IssuedDate,
RANK() OVER(PARTITION BY acct.PolicyNumber, acct.EffectiveDate, acct.PolicyChangeNumber ORDER BY acctvof.Id DESC) AS RN,
acctvof.value
FROM AccountTransaction acct
INNER JOIN AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 
--acct.PolicyNumber in (''AU100228213-01'',''AU100228074-01'',''AU100016182-03'',''AU100103566-02'',''AU100019342-02'') AND 
acct.[State]=''ISSUED'' and acctvo.objecttype=''Insured''
AND acctvof.Field = ''IsPrimaryInsured''
AND acctvof.[Value] in (''yes'',''true'')
)a where a.rn>1' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Dupe primary insured - Quote' AS validation_sql_desc ,
       'select count(*) from 
(
SELECT acct.PolicyNumber, acct.EffectiveDate, 
RANK() OVER(PARTITION BY acct.PolicyNumber, acct.EffectiveDate ORDER BY acctvof.Id DESC) AS RN,
acctvof.value
FROM Account acct
INNER JOIN AccountObject acctvo ON acctvo.AccountId = acct.Id
INNER JOIN AccountObjectField acctvof ON acctvof.ObjectId = acctvo.id
WHERE 
--acct.PolicyNumber in (''AU100228213-01'',''AU100228074-01'',''AU100016182-03'',''AU100103566-02'',''AU100019342-02'') AND 
 acctvo.objecttype=''Insured'' AND acctvof.Field = ''IsPrimaryInsured'' AND acctvof.[Value] in (''yes'',''true'')
)a where a.rn>1' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Missing Insurance Score - Home' AS validation_sql_desc ,
       'select count(*) from 
(
SELECT acct.PolicyNumber, acct.EffectiveDate, acct.PolicyChangeNumber, acct.Id,acctvof.versionobjectid,acctvo.objecttype,
acctvof.field,
acctvof.value
FROM AccountTransaction acct
INNER JOIN AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 
--acct.PolicyNumber in (''AU100228213-01'',''AU100228074-01'',''AU100016182-03'',''AU100103566-02'',''AU100019342-02'') AND 
acct.[State]=''ISSUED'' AND acctvof.Field in (''InsuranceScore'') and acctvo.objecttype=''Homeowner'' and 
 isnull(acctvof.[Value],'''') =''''
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransaction - Missing Insurance Score - Auto' AS validation_sql_desc ,
       'select count(*) from 
(
SELECT acct.PolicyNumber, acct.EffectiveDate, acct.PolicyChangeNumber, acct.Id,acctvof.versionobjectid,acctvo.objecttype,
acctvof.field,
acctvof.value
FROM AccountTransaction acct
INNER JOIN AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 
--acct.PolicyNumber in (''AU100228213-01'',''AU100228074-01'',''AU100016182-03'',''AU100103566-02'',''AU100019342-02'') AND 
acct.[State]=''ISSUED'' AND acctvof.Field in (''InsuranceScore'') and acctvo.objecttype=''Automobile'' and 
 isnull(acctvof.[Value],'''') =''''
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionversionobjectfield - Dupes for Program' AS validation_sql_desc ,
       'select count(*) from 
(
select a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate,a.ExternalSourceId,count(*)
from 
AccountTransaction a , 
AccountTransactionversion b,
AccountTransactionversionobject c,  
AccountTransactionversionobjectfield d
where 
a.id=b.AccountTransactionId and  a.[State]=''ISSUED''
and b.id=c.AccountTransactionVersionId
and c.id=d.VersionObjectId 
and d.Field=''Program'' --and a.PolicyNumber=''CO149813927336-01''
group by a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate,a.ExternalSourceId
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Program mismatch program between AccountTransactionversionobjectfield and account' AS validation_sql_desc ,
       'select count(*) from 
(
select a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate,a.ExternalSourceId,d.[value],e.Program
from 
AccountTransaction a , 
AccountTransactionversion b,
AccountTransactionversionobject c,  
AccountTransactionversionobjectfield d,
account e
where 
a.id=b.AccountTransactionId and  a.[State]=''ISSUED''
and b.id=c.AccountTransactionVersionId
and c.id=d.VersionObjectId and a.AccountId=e.id
and d.Field=''Program'' and a.PolicyNumber=''HO100025858-03''--''HO100025858-03''--''CO149813927336-01''
--and ISNULL(d.[value],''xx'')!=ISNULL(e.Program,''xx'')
and d.[value]!=e.Program
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionVersionObjectField - Missing primary insured = Yes for at least one record' AS validation_sql_desc ,
       'select count(*) from 
(
select distinct PolicyNumber,EffectiveDate from AccountTransaction a 
where not exists 
(select * 
from (
    select a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate into #temp_primaryinsured
from 
AccountTransaction a , 
AccountTransactionversion b,
AccountTransactionversionobject c,
AccountTransactionVersionObjectField d
where 
a.id=b.AccountTransactionId and  a.[State]=''ISSUED''
and b.id=c.AccountTransactionVersionId
and c.ObjectType=''Insured''
and c.id=d.VersionObjectId and d.field = ''IsPrimaryInsured'' and d.Value in (''True'',''Yes'')
)b 
where a.PolicyNumber=b.PolicyNumber and a.EffectiveDate=b.EffectiveDate
and a.PolicyChangeNumber=b.PolicyChangeNumber ) 
and [State]=''ISSUED''
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - AccountTransactionversionobjectfield - Dupes for Collections ClassType' AS validation_sql_desc ,
       'select count(*) from 
(
select a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate,[IssuedDate],[Value],count(*),min(d.versionobjectid),max(d.versionobjectid)
from 
AccountTransaction a , 
AccountTransactionversion b,
AccountTransactionversionobject c,  
AccountTransactionversionobjectfield d
where 
a.id=b.AccountTransactionId and  a.[State]=''ISSUED''
and b.id=c.AccountTransactionVersionId
and c.id=d.VersionObjectId 
and c.objecttype=''collectionclass'' and d.field=''ClassType''
group by a.PolicyNumber,PolicyChangeNumber,a.EffectiveDate,[IssuedDate],[value]
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
	   
--
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Metal Validation - Accountobjectfield - Dupes for Collections ClassType' AS validation_sql_desc ,
       'select count(*) from 
(
select a.PolicyNumber,a.EffectiveDate,a.UpdatedDate,[value],count(*),,min(d.versionobjectid),max(d.versionobjectid)
from 
Account a , 
Accountobject c,  
Accountobjectfield d
where 
a.id=c.AccountId and c.id=d.objectid
and c.objecttype=''collectionclass'' and d.field=''ClassType''
group by a.PolicyNumber,a.EffectiveDate,a.UpdatedDate,[value]
having count(*)>1
) a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;