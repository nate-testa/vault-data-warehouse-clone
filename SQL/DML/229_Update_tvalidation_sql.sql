
update edw_core.tvalidation_sql
set
source_sql= 'select count(*) from edw_integration.policy_current_carrier_auto_np01_feed
where PolicyHolderMailAddressState not in(select state_cd from edw_core.tstate)' 
where
	validation_sql_desc = 'Current Carrier NP01- States outside the USA '

update edw_core.tvalidation_sql
set
source_sql= 'select count(*)
from edw_integration.policy_current_carrier_auto_PR01_feed pccapf 
where 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(VIN)),'''') = ''''
)'
where
	validation_sql_desc = 'Current Carrier  PR01- Missing required fields'

update edw_core.tvalidation_sql
set
source_sql= 'select count(distinct mailing_address_state_cd) from edw_integration.customer_hubspot_feed
where mailing_address_state_cd not in ( select state_cd from edw_core.tstate)
and   mailing_address_state_cd not in (''BC'',''England'',''London'',''NSW'',''ON'',''PR'',''QC'')
and update_ts >= DATEADD(day, -2, getdaTE())'
where
	validation_sql_desc = 'New state in hubspot customer feed'

update edw_core.tvalidation_sql
set
source_sql= 'select count(*) 
from edw_integration.policy_current_carrier_auto_vr01_feed pccavf 
WHERE 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''')  = '''' OR
ISNULL(LTRIM(RTRIM(VIN)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(VehicleAddDate)),'''') = ''''
)'  
where
	validation_sql_desc = 'Current Carrier VR01- Missing required fields'


update edw_core.tvalidation_sql
set
source_sql= 'SELECT COUNT(br.broker_id)
FROM 
    edw_core.tbroker br
WHERE 
    br.broker_id IN (
        SELECT broker_id 
        FROM edw_core.tpolicy
        UNION
        SELECT broker_id 
        FROM edw_core.tquote
    )
    AND br.broker_id IN (
        SELECT broker_id 
        FROM edw_commercial.tcommercial_policy
        UNION
        SELECT broker_id 
        FROM edw_commercial.tcommercial_quote
    )' 
where
	validation_sql_desc = 'Broker - Brokers with policies or quotes in both commercial and personal lines'

update edw_core.tvalidation_sql
set
source_sql= 'select count(*)
from
	edw_core.tclaim_feature cf
inner join edw_core.tclaim c 
on
	cf.claim_sk = c.claim_sk
where
	cf.claim_coverage_desc = ''Comprehensive''
	and c.fault_decision = ''insured'''
where
validation_sql_desc = 'Clue Auto - ClaimType CP has at_fault_indicator = ''A'''

update edw_core.tvalidation_sql
set
source_sql= 'SELECT count(*) FROM edw_integration.claim_clue_property_feed WHERE 
        LTRIM(RTRIM(riskAddressStreetName)) = '''' OR
        LTRIM(RTRIM(riskAddressState)) = '''' OR
        LTRIM(RTRIM(riskAddressZip)) = '''' OR
        LTRIM(RTRIM(riskAddressCity)) = '''' OR
        LTRIM(RTRIM(policyHolderNameFirst)) = '''' OR
        LTRIM(RTRIM(policyHolderNameLast)) = '''' OR
        LTRIM(RTRIM(claimReportingStatus)) = '''' OR
        LTRIM(RTRIM(claimAmount)) = '''' OR
        LTRIM(RTRIM(causeOfLoss)) = '''' OR
        LTRIM(RTRIM(policyNumber)) = '''' OR
        LTRIM(RTRIM(policyType)) = '''' OR
        LTRIM(RTRIM(contribCompany)) = '''' OR
        LTRIM(RTRIM(claimNumber)) = '''' OR
        claimAmount LIKE ''%-%'''
where
validation_sql_desc = 'CLUE Property feed validation - invalid format data'

update edw_core.tvalidation_sql
set
source_sql='select count(*) FROM edw_core.tpolicy where policy_no like ''%-%'' and policy_term = ''new'' and source_system_sk <> 1'

where
validation_sql_desc = 'tpolicy - renewal policy termed as new'
   
update edw_core.tvalidation_sql
set
source_sql='SELECT count(*)
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
'
where
validation_sql_desc = 'Home/Condo field invalid values'


update edw_core.tvalidation_sql
set
source_sql='
SELECT count(*)
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
'
where
validation_sql_desc = 'Auto field invalid values'

update edw_core.tvalidation_sql
set
source_sql= 'SELECT count(*) FROM  
  (  
  SELECT acctvof.[field],acctvof.[value],  pofv.[Value] as povf_value  
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
' 
where
validation_sql_desc = 'Excess Liability field invalid values'



update edw_core.tvalidation_sql
set
source_sql= 'SELECT count(*) FROM  
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
' 
where
validation_sql_desc = 'Collection field invalid values'


