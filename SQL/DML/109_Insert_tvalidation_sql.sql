INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Home/Condo field invalid values' as validation_sql_desc,
'
SELECT
	count(*) as ct
FROM
(
SELECT 
acctvof.[field],acctvof.[value],
pofv.[Value] as povf_value
FROM 
edw_stage.Account acc
INNER JOIN edw_stage.[AccountTransaction] acct on acc.Id = acct.AccountId
INNER JOIN edw_stage.[Product] p on p.Id= acct.ProductId

INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER  JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id 
LEFT JOIN edw_stage.ProductObjectFieldValueDisplay AS pofv ON pofv.ProductId = p.Id
	and pofv.field = acctvof.field
	and pofv.productid = acct.productid
	and pofv.objecttype = acctvo.objecttype
	AND pofv.statecode = acctv.RiskStateCode 
	AND pofv.[Value] = acctvof.[Value]	
	and cast(pofv.effectivedate as date) < = cast(acct.EffectiveDate as date)
where
p.[Name] in (''Condo'',''Homeowners'')
and 
acctvof.Field in 
(
''CoverageE'', ''CoverageF'', ''AopDeductible'', ''WaterDeductible'',
''HurricaneDeductible'',''HurricaneOrNamedStormDeductible'',''NamedStormDeductible'',''TornadoorHailstormDeductible'',
''WindStormOrHailDeductible'',''WildfireDeductible'',''DeductibleWaiverLargeLossesLimit'',''EarthquakeCoverageExtensionDeductible'',
''EarthquakeCoverageExtensionLossAssessmentLimit'',''FungiBacteriaIncreaseLimit'',''HomeSystemsProtectionLimit'',''HomeCyberProtectionCoverageDeductible'',
''HomeCyberProtectionCoverageLimit'',''EarthquakeEndorsementDeductible'',''WaterDamageLimitationEndorsementLimit'',''WaterDamageSubLimitAmount''
)

and datediff(day,cast(acc.UpdatedDate as date),cast(getdate() as date)) = 1
) AS a
where
	case
when ltrim(rtrim([value])) = '''' and povf_value is null then ''No''
when isnull([value],'''') = isnull(povf_value,'''') then ''Yes'' else ''No''
end = ''No''	
' AS source_sql ,
       'select 0' AS target_sql ,
       'N' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;


INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Auto field invalid values' as validation_sql_desc, 
'
SELECT
	count(*) as ct
FROM
(
SELECT 
acctvof.[field],acctvof.[value],
pofv.[Value] as povf_value
FROM 
edw_stage.Account acc
INNER JOIN edw_stage.[AccountTransaction] acct on acc.Id = acct.AccountId
INNER JOIN edw_stage.[Product] p on p.Id= acct.ProductId

INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER  JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id 
LEFT JOIN edw_stage.ProductObjectFieldValueDisplay AS pofv ON pofv.ProductId = p.Id
	and pofv.field = acctvof.field
	and pofv.productid = acct.productid
	and pofv.objecttype = acctvo.objecttype
	AND pofv.statecode = acctv.RiskStateCode 
	AND pofv.[Value] = acctvof.[Value]	
	and cast(pofv.effectivedate as date) < = cast(acct.EffectiveDate as date)
where
p.[Name] in (''Automobile'')
and 
acctvof.Field in 
(
''CombinedSingleLimit'',''BILimit'',''PDLimit'',''UMLimit'',''UIMLimit'',''CombinedUMLimit'',''CombinedUIMLimit'',''UMBIPolicyLimit'',''UMPDPolicyLimit'',
''CombinedUMBIPolicyLimit'',''CombinedUMPDPolicyLimit'',''PIPLimit'',''PIPDeductible'',''MedicalPaymentLimit'',''ExtendedMedical'',
''OTCDeductible'',''COLLDeductible''
)

and datediff(day,cast(acc.UpdatedDate as date),cast(getdate() as date)) = 1
) AS a
where
	case
when ltrim(rtrim([value])) = '''' and povf_value is null then ''No''
when isnull([value],'''') = isnull(povf_value,'''') then ''Yes'' else ''No''
end = ''No''	
' AS source_sql ,
       'select 0' AS target_sql ,
       'N' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;



INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Excess Liability field invalid values' as validation_sql_desc,
'
  SELECT  count(*) as ct  FROM  
  (  
  SELECT   acctvof.[field],acctvof.[value],  pofv.[Value] as povf_value  
  FROM   edw_stage.Account acc  INNER JOIN edw_stage.[AccountTransaction] acct on acc.Id = acct.AccountId  
  INNER JOIN edw_stage.[Product] p on p.Id= acct.ProductId    
  INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id  
  INNER  JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id 
  INNER JOIN edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id   
  LEFT JOIN edw_stage.ProductObjectFieldValueDisplay AS pofv ON pofv.ProductId = p.Id  and pofv.field = acctvof.field  and pofv.productid = acct.productid  
  and pofv.objecttype = acctvo.objecttype   AND pofv.statecode = acctv.RiskStateCode AND pofv.[Value] = acctvof.[Value]  
  and cast(pofv.effectivedate as date) < = cast(acct.EffectiveDate as date)  
  where  
  p.[Name] in (''PersonalExcessLiability'')  and
  acctvof.Field in
  ( 
  ''CoverageLimit'', ''UnderinsuredMotoristLiability'', ''UnderinsuredLiability'', ''EmploymentPracticesLiabilityLimit'',
  ''DONotForProfitLimit''
  )
  and datediff(day,cast(acc.UpdatedDate as date),cast(getdate() as date)) = 1  ) AS a  
  where 
	case 
		when ltrim(rtrim([value])) = '''' and povf_value is null then ''No''
		when isnull([value],'''') = isnull(povf_value,'''') then ''Yes''
		else ''No''
	end = ''No''	
' AS source_sql ,
       'select 0' AS target_sql ,
       'N' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;



INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Collection field invalid values' as validation_sql_desc,
'
  SELECT  count(*) as ct  FROM  
  (  
  SELECT   acctvof.[field],acctvof.[value],  pofv.[Value] as povf_value  
  FROM   edw_stage.Account acc  INNER JOIN edw_stage.[AccountTransaction] acct on acc.Id = acct.AccountId  
  INNER JOIN edw_stage.[Product] p on p.Id= acct.ProductId    
  INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id  
  INNER  JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id 
  INNER JOIN edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id   
  LEFT JOIN edw_stage.ProductObjectFieldValueDisplay AS pofv ON pofv.ProductId = p.Id  and pofv.field = acctvof.field  and pofv.productid = acct.productid  
  and pofv.objecttype = acctvo.objecttype   AND pofv.statecode = acctv.RiskStateCode AND pofv.[Value] = acctvof.[Value]  
  and cast(pofv.effectivedate as date) < = cast(acct.EffectiveDate as date)  
  where  
  p.[Name] in (''Collections'')  and
  acctvof.Field in
  ( 
  ''CoverageDeductibleAmount'', ''HurricaneDeductibleLimit'', ''EarthquakeDeductibleAmount'', ''WildfireDeductibleAmount''
  )
  and datediff(day,cast(acc.UpdatedDate as date),cast(getdate() as date)) = 1  ) AS a  
  where 
	case 
		when ltrim(rtrim([value])) = '''' and povf_value is null then ''No''
		when isnull([value],'''') = isnull(povf_value,'''') then ''Yes''
		else ''No''
	end = ''No''	
' AS source_sql ,
       'select 0' AS target_sql ,
       'N' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;