--Control tables
select top 100 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;

-- Error Number:4083 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_tquote_auto_vehicle_coverage Error Line:1027 Error Message:The connection was recovered and rowcount in the first query is not available. Please execute another query to get a valid rowcount.

SELECT * FROM [edw_temp].[tquote_auto_vehicle_coverage_wip_temp1] WHERE vehicle_no IS NULL;
SELECT * FROM [edw_temp].[tquote_auto_vehicle_coverage_temp3] WHERE vehicle_no IS NULL;

SELECT * FROM [edw_stage].[Account] WHERE PolicyNumber in ('AU200023700','AU200026773','AU200026774-01');

-- UPDATE [edw_stage].[Account] SET CreatedDate = '1900-01-01 00:00:00', UpdatedDate = '1900-01-01 00:00:00' WHERE PolicyNumber in ('AU200023700','AU200026773','AU200026774-01');

--------------------------------------

-- sp_tauto_vehicle_coverage
select top 100 * from edw_core.tetl_audit where process_nm like '%tauto_vehicle_coverage%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm = 'sp_tauto_vehicle_coverage';
-- truncate table [edw_core].[tauto_vehicle_coverage];
EXEC [edw_core].[sp_tauto_vehicle_coverage];
select count(1) from [edw_core].[tauto_vehicle_coverage];
select top 100 * from [edw_core].[tauto_vehicle_coverage];

-- sp_tquote_auto_vehicle_coverage]
select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_auto_vehicle_coverage%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm = 'sp_tquote_auto_vehicle_coverage';
-- truncate table [edw_core].[tquote_auto_vehicle_coverage];
EXEC [edw_core].[sp_tquote_auto_vehicle_coverage];
select count(1) from [edw_core].[tquote_auto_vehicle_coverage];
select top 100 * from [edw_core].[tquote_auto_vehicle_coverage];

-- sp_tquote_auto_vehicle_coverage_wip]
select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_auto_vehicle_coverage_wip%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm = 'sp_tquote_auto_vehicle_coverage_wip';
EXEC [edw_core].[sp_tquote_auto_vehicle_coverage_wip];
select count(1) from [edw_core].[tquote_auto_vehicle_coverage];
select top 100 * from [edw_core].[tquote_auto_vehicle_coverage];

select top 100 * from [edw_core].[tquote_auto_vehicle_coverage] where quote_no = 'AU200026789';
select top 100 * from [edw_core].[tauto_vehicle_coverage] where policy_no = 'AU200026789';

-- select top 100 * from [edw_core].[tauto_vehicle_coverage]
select top 100 * from [edw_core].[tquote_auto_vehicle_coverage]
where added_first_party_premium_adjustment_amount is not null
or added_first_party_premium_adjustment_method is not null
or added_first_party_premium_adjustment_reason is not null
or added_first_party_premium_adjustment_retention is not null
or added_personal_injury_protection_premium_adjustment_amount is not null
or added_personal_injury_protection_premium_adjustment_method is not null
or added_personal_injury_protection_premium_adjustment_reason is not null
or added_personal_injury_protection_premium_adjustment_retention is not null
or basic_first_party_premium_adjustment_amount is not null
or basic_first_party_premium_adjustment_method is not null
or basic_first_party_premium_adjustment_reason is not null
or basic_first_party_premium_adjustment_retention is not null
or customized_premium_adjustment_amount is not null
or customized_premium_adjustment_method is not null
or customized_premium_adjustment_reason is not null
or customized_premium_adjustment_retention is not null
or fire_premium_adjustment_amount is not null
or fire_premium_adjustment_method is not null
or fire_premium_adjustment_reason is not null
or fire_premium_adjustment_retention is not null
or property_protection_insurance_premium_adjustment_amount is not null
or property_protection_insurance_premium_adjustment_method is not null
or property_protection_insurance_premium_adjustment_reason is not null
or property_protection_insurance_premium_adjustment_retention is not null
or theft_premium_adjustment_amount is not null
or theft_premium_adjustment_method is not null
or theft_premium_adjustment_reason is not null
or theft_premium_adjustment_retention is not null
or uninsured_bodily_injury_premium_adjustment_amount is not null
or uninsured_bodily_injury_premium_adjustment_method is not null
or uninsured_bodily_injury_premium_adjustment_reason is not null
or uninsured_bodily_injury_premium_adjustment_retention is not null
or underinsured_motorist_premium_adjustment_amount is not null
or underinsured_motorist_premium_adjustment_method is not null
or underinsured_motorist_premium_adjustment_reason is not null
or underinsured_motorist_premium_adjustment_retention is not null
or uninsured_property_damage_premium_adjustment_amount is not null
or uninsured_property_damage_premium_adjustment_method is not null
or uninsured_property_damage_premium_adjustment_reason is not null
or uninsured_property_damage_premium_adjustment_retention is not null
;

exec sp_help 'edw_core.tauto_vehicle_coverage';

select distinct underinsured_motorist_premium_adjustment_method, uninsured_motorist_premium_adjustment_method from edw_core.tauto_vehicle_coverage;

 

SELECT  
    acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.policychangenumber,
    acctvpf.AccountTransactionVersionPremiumId,
    acctvpf.ObjectUniqueId,
    acctvpf.Coverage,
    CONCAT(
        CASE 
            WHEN Coverage = 'Extended Towing and Labor' THEN 'extended_towing_labor'
            ELSE LOWER(REPLACE(Coverage,' ','_'))
        END
        ,'_premium_adjustment'
    ) AS FinalColumnName,
    acctvpf.FactorMethod AS method,
    CONVERT(nvarchar(3000), acctvpf.Factor) AS amount,
    acctvpf.Retention AS [retention],
    acctvpf.Reason AS reason
FROM [edw_stage].[AccountTransaction] AS acct
INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
WHERE acct.[State] = 'ISSUED'
AND acct.PolicyNumber =  'AU100053419-02'
-- AND acct.IssuedDate > @last_source_extract_ts
-- AND acctvpf.Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor')
-- AND acctvpf.Coverage IN ('Added First Party','Added Personal Injury Protection','Basic First Party','Customized','Fire','Property Protection Insurance','Theft','Uninsured Bodily Injury','Uninsured Property Damage')
AND acctvpf.Coverage = 'Uninsured Motorist'
AND p.[Name] = 'Automobile'
AND p.ProductLine = 'PersonalLines'
;

select a.policy_no , a.vehicle_no , a.auto_vehicle_sk , tv.vehicle_make  ,
underinsured_motorist_premium_adjustment_amount , underinsured_motorist_premium_adjustment_method ,
underinsured_motorist_premium_adjustment_reason , uninsured_motorist_premium_adjustment_method , uninsured_motorist_premium_adjustment_amount
from [edw_core].[tauto_vehicle_coverage] a left join
edw_core.tauto_vehicle tv
on a.auto_vehicle_sk = tv.auto_vehicle_sk
where a.policy_no =  'AU100053419-02'
;