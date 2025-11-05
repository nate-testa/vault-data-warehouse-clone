-- SELECT COUNT(1) FROM edw_core.tquote_auto_vehicle_coverage;
-- EXEC SP_HELP '[edw_core].[tquote_auto_vehicle_coverage]';

--1) Drop table
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp2;
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp3;

--2) Create temp table
SELECT  
	acc.PolicyNumber, acc.EffectiveDate, 0 as Number,
	accpf.AccountPremiumId,
	accpf.ObjectUniqueId,
	accpf.Coverage,
	CONCAT(
		CASE 
			WHEN Coverage = 'Extended Towing and Labor' THEN 'extended_towing_labor'
			ELSE LOWER(REPLACE(Coverage,' ','_'))
		END
		,'_premium_adjustment'
	) AS FinalColumnName,
	accpf.FactorMethod AS method,
	CONVERT(nvarchar(3000), accpf.Factor) AS amount,
	accpf.Retention AS [retention],
	accpf.Reason AS reason
INTO edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1
FROM [edw_stage].[Account] acc
INNER JOIN [edw_stage].[Product] p ON p.Id = acc.ProductId
INNER JOIN [edw_stage].[AccountPremium] AS accp ON accp.AccountId = acc.id
INNER JOIN [edw_stage].[AccountPremiumFactor] AS accpf ON accpf.AccountPremiumId = accp.id
WHERE accpf.Coverage IN ('Underinsured Motorist','Added First Party','Added Personal Injury Protection','Basic First Party','Customized','Fire','Property Protection Insurance','Theft','Uninsured Bodily Injury','Uninsured Property Damage','Uninsured Motorist')
AND p.[Name] = 'Automobile'
AND p.ProductLine = 'PersonalLines'
AND NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=acc.id)

SELECT * 
INTO edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp2
FROM (
	SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1 WHERE method IS NOT NULL
	UNION ALL
	SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_amount') AS FinalColumnName, amount           as FinalValue FROM edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1 WHERE amount IS NOT NULL
	UNION ALL
	SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1 WHERE [retention] IS NOT NULL
	UNION ALL
	SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_reason') AS FinalColumnName, reason           as FinalValue FROM edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1 WHERE reason IS NOT NULL
) AS temp2

SELECT
	PolicyNumber, EffectiveDate, Number
	,ObjectUniqueId
	,uninsured_motorist_premium_adjustment_method
	,uninsured_motorist_premium_adjustment_amount
	,uninsured_motorist_premium_adjustment_retention
	,uninsured_motorist_premium_adjustment_reason
	,added_first_party_premium_adjustment_amount
	,added_first_party_premium_adjustment_method
	,added_first_party_premium_adjustment_reason
	,added_first_party_premium_adjustment_retention
	,added_personal_injury_protection_premium_adjustment_amount
	,added_personal_injury_protection_premium_adjustment_method
	,added_personal_injury_protection_premium_adjustment_reason
	,added_personal_injury_protection_premium_adjustment_retention
	,basic_first_party_premium_adjustment_amount
	,basic_first_party_premium_adjustment_method
	,basic_first_party_premium_adjustment_reason
	,basic_first_party_premium_adjustment_retention
	,customized_premium_adjustment_amount
	,customized_premium_adjustment_method
	,customized_premium_adjustment_reason
	,customized_premium_adjustment_retention
	,fire_premium_adjustment_amount
	,fire_premium_adjustment_method
	,fire_premium_adjustment_reason
	,fire_premium_adjustment_retention
	,property_protection_insurance_premium_adjustment_amount
	,property_protection_insurance_premium_adjustment_method
	,property_protection_insurance_premium_adjustment_reason
	,property_protection_insurance_premium_adjustment_retention
	,theft_premium_adjustment_amount
	,theft_premium_adjustment_method
	,theft_premium_adjustment_reason
	,theft_premium_adjustment_retention
	,uninsured_bodily_injury_premium_adjustment_amount
	,uninsured_bodily_injury_premium_adjustment_method
	,uninsured_bodily_injury_premium_adjustment_reason
	,uninsured_bodily_injury_premium_adjustment_retention
	,underinsured_motorist_premium_adjustment_amount
	,underinsured_motorist_premium_adjustment_method
	,underinsured_motorist_premium_adjustment_reason
	,underinsured_motorist_premium_adjustment_retention
	,uninsured_property_damage_premium_adjustment_amount
	,uninsured_property_damage_premium_adjustment_method
	,uninsured_property_damage_premium_adjustment_reason
	,uninsured_property_damage_premium_adjustment_retention
INTO [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_temp3]
FROM [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_temp2]
PIVOT 
(
	MAX(FinalValue) FOR FinalColumnName IN (
		 uninsured_motorist_premium_adjustment_method
		,uninsured_motorist_premium_adjustment_amount
		,uninsured_motorist_premium_adjustment_retention
		,uninsured_motorist_premium_adjustment_reason
		,added_first_party_premium_adjustment_amount
		,added_first_party_premium_adjustment_method
		,added_first_party_premium_adjustment_reason
		,added_first_party_premium_adjustment_retention
		,added_personal_injury_protection_premium_adjustment_amount
		,added_personal_injury_protection_premium_adjustment_method
		,added_personal_injury_protection_premium_adjustment_reason
		,added_personal_injury_protection_premium_adjustment_retention
		,basic_first_party_premium_adjustment_amount
		,basic_first_party_premium_adjustment_method
		,basic_first_party_premium_adjustment_reason
		,basic_first_party_premium_adjustment_retention
		,customized_premium_adjustment_amount
		,customized_premium_adjustment_method
		,customized_premium_adjustment_reason
		,customized_premium_adjustment_retention
		,fire_premium_adjustment_amount
		,fire_premium_adjustment_method
		,fire_premium_adjustment_reason
		,fire_premium_adjustment_retention
		,property_protection_insurance_premium_adjustment_amount
		,property_protection_insurance_premium_adjustment_method
		,property_protection_insurance_premium_adjustment_reason
		,property_protection_insurance_premium_adjustment_retention
		,theft_premium_adjustment_amount
		,theft_premium_adjustment_method
		,theft_premium_adjustment_reason
		,theft_premium_adjustment_retention
		,uninsured_bodily_injury_premium_adjustment_amount
		,uninsured_bodily_injury_premium_adjustment_method
		,uninsured_bodily_injury_premium_adjustment_reason
		,uninsured_bodily_injury_premium_adjustment_retention
		,underinsured_motorist_premium_adjustment_amount
		,underinsured_motorist_premium_adjustment_method
		,underinsured_motorist_premium_adjustment_reason
		,underinsured_motorist_premium_adjustment_retention
		,uninsured_property_damage_premium_adjustment_amount
		,uninsured_property_damage_premium_adjustment_method
		,uninsured_property_damage_premium_adjustment_reason
		,uninsured_property_damage_premium_adjustment_retention
	)
) AS pvt
;

--3) Update Final table
UPDATE a 
SET  a.uninsured_motorist_premium_adjustment_method = b.uninsured_motorist_premium_adjustment_method
	,a.uninsured_motorist_premium_adjustment_amount = b.uninsured_motorist_premium_adjustment_amount
	,a.uninsured_motorist_premium_adjustment_retention = b.uninsured_motorist_premium_adjustment_retention
	,a.uninsured_motorist_premium_adjustment_reason = b.uninsured_motorist_premium_adjustment_reason
	,a.added_first_party_premium_adjustment_amount = b.added_first_party_premium_adjustment_amount
	,a.added_first_party_premium_adjustment_method = b.added_first_party_premium_adjustment_method
	,a.added_first_party_premium_adjustment_reason = b.added_first_party_premium_adjustment_reason
	,a.added_first_party_premium_adjustment_retention = b.added_first_party_premium_adjustment_retention
	,a.added_personal_injury_protection_premium_adjustment_amount = b.added_personal_injury_protection_premium_adjustment_amount
	,a.added_personal_injury_protection_premium_adjustment_method = b.added_personal_injury_protection_premium_adjustment_method
	,a.added_personal_injury_protection_premium_adjustment_reason = b.added_personal_injury_protection_premium_adjustment_reason
	,a.added_personal_injury_protection_premium_adjustment_retention = b.added_personal_injury_protection_premium_adjustment_retention
	,a.basic_first_party_premium_adjustment_amount = b.basic_first_party_premium_adjustment_amount
	,a.basic_first_party_premium_adjustment_method = b.basic_first_party_premium_adjustment_method
	,a.basic_first_party_premium_adjustment_reason = b.basic_first_party_premium_adjustment_reason
	,a.basic_first_party_premium_adjustment_retention = b.basic_first_party_premium_adjustment_retention
	,a.customized_premium_adjustment_amount = b.customized_premium_adjustment_amount
	,a.customized_premium_adjustment_method = b.customized_premium_adjustment_method
	,a.customized_premium_adjustment_reason = b.customized_premium_adjustment_reason
	,a.customized_premium_adjustment_retention = b.customized_premium_adjustment_retention
	,a.fire_premium_adjustment_amount = b.fire_premium_adjustment_amount
	,a.fire_premium_adjustment_method = b.fire_premium_adjustment_method
	,a.fire_premium_adjustment_reason = b.fire_premium_adjustment_reason
	,a.fire_premium_adjustment_retention = b.fire_premium_adjustment_retention
	,a.property_protection_insurance_premium_adjustment_amount = b.property_protection_insurance_premium_adjustment_amount
	,a.property_protection_insurance_premium_adjustment_method = b.property_protection_insurance_premium_adjustment_method
	,a.property_protection_insurance_premium_adjustment_reason = b.property_protection_insurance_premium_adjustment_reason
	,a.property_protection_insurance_premium_adjustment_retention = b.property_protection_insurance_premium_adjustment_retention
	,a.theft_premium_adjustment_amount = b.theft_premium_adjustment_amount
	,a.theft_premium_adjustment_method = b.theft_premium_adjustment_method
	,a.theft_premium_adjustment_reason = b.theft_premium_adjustment_reason
	,a.theft_premium_adjustment_retention = b.theft_premium_adjustment_retention
	,a.uninsured_bodily_injury_premium_adjustment_amount = b.uninsured_bodily_injury_premium_adjustment_amount
	,a.uninsured_bodily_injury_premium_adjustment_method = b.uninsured_bodily_injury_premium_adjustment_method
	,a.uninsured_bodily_injury_premium_adjustment_reason = b.uninsured_bodily_injury_premium_adjustment_reason
	,a.uninsured_bodily_injury_premium_adjustment_retention = b.uninsured_bodily_injury_premium_adjustment_retention
	,a.underinsured_motorist_premium_adjustment_amount = b.underinsured_motorist_premium_adjustment_amount
	,a.underinsured_motorist_premium_adjustment_method = b.underinsured_motorist_premium_adjustment_method
	,a.underinsured_motorist_premium_adjustment_reason = b.underinsured_motorist_premium_adjustment_reason
	,a.underinsured_motorist_premium_adjustment_retention = b.underinsured_motorist_premium_adjustment_retention
	,a.uninsured_property_damage_premium_adjustment_amount = b.uninsured_property_damage_premium_adjustment_amount
	,a.uninsured_property_damage_premium_adjustment_method = b.uninsured_property_damage_premium_adjustment_method
	,a.uninsured_property_damage_premium_adjustment_reason = b.uninsured_property_damage_premium_adjustment_reason
	,a.uninsured_property_damage_premium_adjustment_retention = b.uninsured_property_damage_premium_adjustment_retention
FROM edw_core.tquote_auto_vehicle_coverage a
INNER JOIN edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp3 b
ON a.quote_no = b.PolicyNumber  
AND a.effective_dt = b.EffectiveDate 
AND a.transaction_seq_no = b.Number
AND a.vehicle_unique_id = b.ObjectUniqueId 
;


--4) Drop table
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp2;
DROP TABLE IF EXISTS edw_temp.tquote_auto_vehicle_coverage_wip_backfill_temp3;


--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

SELECT count(1) FROM edw_core.tquote_auto_vehicle_coverage t--12166
WHERE t.uninsured_motorist_premium_adjustment_method is not null
or t.uninsured_motorist_premium_adjustment_amount is not null
or t.uninsured_motorist_premium_adjustment_retention is not null
or t.uninsured_motorist_premium_adjustment_reason is not null
or t.added_first_party_premium_adjustment_amount is not null
or t.added_first_party_premium_adjustment_method is not null
or t.added_first_party_premium_adjustment_reason is not null
or t.added_first_party_premium_adjustment_retention is not null
or t.added_personal_injury_protection_premium_adjustment_amount is not null
or t.added_personal_injury_protection_premium_adjustment_method is not null
or t.added_personal_injury_protection_premium_adjustment_reason is not null
or t.added_personal_injury_protection_premium_adjustment_retention is not null
or t.basic_first_party_premium_adjustment_amount is not null
or t.basic_first_party_premium_adjustment_method is not null
or t.basic_first_party_premium_adjustment_reason is not null
or t.basic_first_party_premium_adjustment_retention is not null
or t.customized_premium_adjustment_amount is not null
or t.customized_premium_adjustment_method is not null
or t.customized_premium_adjustment_reason is not null
or t.customized_premium_adjustment_retention is not null
or t.fire_premium_adjustment_amount is not null
or t.fire_premium_adjustment_method is not null
or t.fire_premium_adjustment_reason is not null
or t.fire_premium_adjustment_retention is not null
or t.property_protection_insurance_premium_adjustment_amount is not null
or t.property_protection_insurance_premium_adjustment_method is not null
or t.property_protection_insurance_premium_adjustment_reason is not null
or t.property_protection_insurance_premium_adjustment_retention is not null
or t.theft_premium_adjustment_amount is not null
or t.theft_premium_adjustment_method is not null
or t.theft_premium_adjustment_reason is not null
or t.theft_premium_adjustment_retention is not null
or t.uninsured_bodily_injury_premium_adjustment_amount is not null
or t.uninsured_bodily_injury_premium_adjustment_method is not null
or t.uninsured_bodily_injury_premium_adjustment_reason is not null
or t.uninsured_bodily_injury_premium_adjustment_retention is not null
or t.underinsured_motorist_premium_adjustment_amount is not null
or t.underinsured_motorist_premium_adjustment_method is not null
or t.underinsured_motorist_premium_adjustment_reason is not null
or t.underinsured_motorist_premium_adjustment_retention is not null
or t.uninsured_property_damage_premium_adjustment_amount is not null
or t.uninsured_property_damage_premium_adjustment_method is not null
or t.uninsured_property_damage_premium_adjustment_reason is not null
or t.uninsured_property_damage_premium_adjustment_retention is not null
;
