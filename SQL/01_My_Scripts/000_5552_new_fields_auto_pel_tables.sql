select count(1) from [edw_core].[tauto_vehicle_coverage];
select * from [edw_core].[tauto_vehicle_coverage];
update edw_core.tetl_control set last_source_extract_ts = '2023-06-01 00:00:00' where process_nm in ('sp_tauto_vehicle_coverage');
truncate table [edw_core].[tauto_vehicle_coverage];
EXEC [edw_core].[sp_tauto_vehicle_coverage];


select count(1) from [edw_core].[tquote_auto_vehicle_coverage];
select * from [edw_core].[tquote_auto_vehicle_coverage];
update edw_core.tetl_control set last_source_extract_ts = '2023-06-01 00:00:00' where process_nm in ('sp_tquote_auto_vehicle_coverage');
truncate table [edw_core].[tquote_auto_vehicle_coverage];
EXEC [edw_core].[sp_tquote_auto_vehicle_coverage];


select count(1) from [edw_core].[tauto_vehicle];
select * from [edw_core].[tauto_vehicle];
update edw_core.tetl_control set last_source_extract_ts = '2023-06-01 00:00:00' where process_nm in ('sp_tauto_vehicle');
truncate table [edw_core].[tauto_vehicle];
EXEC [edw_core].[sp_tauto_vehicle];


select count(1) from [edw_core].[tquote_auto_vehicle];
select * from [edw_core].[tquote_auto_vehicle];
update edw_core.tetl_control set last_source_extract_ts = '2023-06-01 00:00:00' where process_nm in ('sp_tquote_auto_vehicle');
truncate table [edw_core].[tquote_auto_vehicle];
EXEC [edw_core].[sp_tquote_auto_vehicle];

--tauto_vehicle and tquote_auto_vehicle
--****************************************
--****SEARCH COLUMNS FOR POLICY NUMBER****
--****************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'AU100021687-01',
        'AU100011607'
    ) 
    -- OR PolicyNumber LIKE 'CO100051662%'
)
,acctv AS (
    SELECT * FROM edw_stage.AccountTransactionVersion 
    WHERE AccountTransactionId in (select Id from acct)
)
,acctvo AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObject 
    WHERE AccountTransactionVersionId in (select Id from acctv)
)
,acctvof AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE VersionObjectId in (select Id from acctvo)
)
,acctvpf AS (
    SELECT  
        Id,
        AccountTransactionVersionPremiumId,
        ObjectUniqueId,
        Coverage,
        CONCAT(
            CASE 
                WHEN Coverage = 'Extended Towing and Labor' THEN 'extended_towing_labor'
                ELSE LOWER(REPLACE(Coverage,' ','_'))
            END
            ,'_premium_adjustment'
        ) AS FinalColumnName,
        FactorMethod AS method,
        CONVERT(nvarchar(3000), Factor) AS amount,
        [Retention] AS [retention],
        Reason AS reason
    FROM edw_stage.AccountTransactionVersionPremiumFactor 
    WHERE AccountTransactionVersionPremiumId in (select Id from acctv)
    AND Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor')
)
,acctvpf_unpivot AS (
    select Id, AccountTransactionVersionPremiumId, ObjectUniqueId, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method as FinalValue from acctvpf where method is not null
    UNION ALL
    select Id, AccountTransactionVersionPremiumId, ObjectUniqueId, CONCAT(FinalColumnName, '_amount') AS FinalColumnName, amount as FinalValue from acctvpf where amount is not null
    UNION ALL
    select Id, AccountTransactionVersionPremiumId, ObjectUniqueId, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention] as FinalValue from acctvpf where [retention] is not null
    UNION ALL
    select Id, AccountTransactionVersionPremiumId, ObjectUniqueId, CONCAT(FinalColumnName, '_reason') AS FinalColumnName, reason as FinalValue from acctvpf where reason is not null   
)
--***All
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
-- select * from acctvof;
select * from acctvpf;
-- select * from acctvpf_unpivot where AccountTransactionVersionPremiumId = 2090 and ObjectUniqueId = '541f261e-0aec-450c-8ce1-26a963b688df' ;

--***Filters
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
-- SELECT '****acct****' as acct, acct.*, '****acctv****' as acctv, acctv.*, '****acctvo****' as acctvo, acctvo.*, '****acctvof****' as acctvof, acctvof.* 
-- FROM acct
-- INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
-- INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
-- INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
-- WHERE 1=1 
-- AND acctvof.Field = '%rem%'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'ExtendedLiabilityLocation'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'



SELECT
    Id
    ,AccountTransactionVersionPremiumId
    ,ObjectUniqueId
    ,bodily_injury_premium_adjustment_method
    ,bodily_injury_premium_adjustment_amount
    ,bodily_injury_premium_adjustment_retention
    ,bodily_injury_premium_adjustment_reason
    ,property_damage_premium_adjustment_method
    ,property_damage_premium_adjustment_amount
    ,property_damage_premium_adjustment_retention
    ,property_damage_premium_adjustment_reason
    ,medical_payments_premium_adjustment_method
    ,medical_payments_premium_adjustment_amount
    ,medical_payments_premium_adjustment_retention
    ,medical_payments_premium_adjustment_reason
    ,uninsured_motorist_premium_adjustment_method
    ,uninsured_motorist_premium_adjustment_amount
    ,uninsured_motorist_premium_adjustment_retention
    ,uninsured_motorist_premium_adjustment_reason
    ,other_than_collision_premium_adjustment_method
    ,other_than_collision_premium_adjustment_amount
    ,other_than_collision_premium_adjustment_retention
    ,other_than_collision_premium_adjustment_reason
    ,collision_premium_adjustment_method
    ,collision_premium_adjustment_amount
    ,collision_premium_adjustment_retention
    ,collision_premium_adjustment_reason
    ,personal_injury_protection_premium_adjustment_method
    ,personal_injury_protection_premium_adjustment_amount
    ,personal_injury_protection_premium_adjustment_retention
    ,personal_injury_protection_premium_adjustment_reason
    ,extended_towing_labor_premium_adjustment_method
    ,extended_towing_labor_premium_adjustment_amount
    ,extended_towing_labor_premium_adjustment_retention
    ,extended_towing_labor_premium_adjustment_reason
FROM acctvpf_unpivot
PIVOT 
(
    MAX(FinalValue) FOR FinalColumnName IN (
        bodily_injury_premium_adjustment_method
        ,bodily_injury_premium_adjustment_amount
        ,bodily_injury_premium_adjustment_retention
        ,bodily_injury_premium_adjustment_reason
        ,property_damage_premium_adjustment_method
        ,property_damage_premium_adjustment_amount
        ,property_damage_premium_adjustment_retention
        ,property_damage_premium_adjustment_reason
        ,medical_payments_premium_adjustment_method
        ,medical_payments_premium_adjustment_amount
        ,medical_payments_premium_adjustment_retention
        ,medical_payments_premium_adjustment_reason
        ,uninsured_motorist_premium_adjustment_method
        ,uninsured_motorist_premium_adjustment_amount
        ,uninsured_motorist_premium_adjustment_retention
        ,uninsured_motorist_premium_adjustment_reason
        ,other_than_collision_premium_adjustment_method
        ,other_than_collision_premium_adjustment_amount
        ,other_than_collision_premium_adjustment_retention
        ,other_than_collision_premium_adjustment_reason
        ,collision_premium_adjustment_method
        ,collision_premium_adjustment_amount
        ,collision_premium_adjustment_retention
        ,collision_premium_adjustment_reason
        ,personal_injury_protection_premium_adjustment_method
        ,personal_injury_protection_premium_adjustment_amount
        ,personal_injury_protection_premium_adjustment_retention
        ,personal_injury_protection_premium_adjustment_reason
        ,extended_towing_labor_premium_adjustment_method
        ,extended_towing_labor_premium_adjustment_amount
        ,extended_towing_labor_premium_adjustment_retention
        ,extended_towing_labor_premium_adjustment_reason
    )
) AS pvt
;



;

--------------------------------------------------------------------

SELECT 
    Id,
    AccountTransactionVersionPremiumId,
    ObjectUniqueId,
    Bodily_Injury_method AS Bodily_Injury_FactorMethod,
    Bodily_Injury_amount AS Bodily_Injury_Factor,
    Bodily_Injury_retention AS Bodily_Injury_Retention,
    Bodily_Injury_reason AS Bodily_Injury_Reason,
    Property_Damage_method AS Property_Damage_FactorMethod,
    Property_Damage_amount AS Property_Damage_Factor,
    Property_Damage_retention AS Property_Damage_Retention,
    Property_Damage_reason AS Property_Damage_Reason,
    Medical_Payments_method AS Medical_Payments_FactorMethod,
    Medical_Payments_amount AS Medical_Payments_Factor,
    Medical_Payments_retention AS Medical_Payments_Retention,
    Medical_Payments_reason AS Medical_Payments_Reason,
    Underinsured_Motorist_method AS Underinsured_Motorist_FactorMethod,
    Underinsured_Motorist_amount AS Underinsured_Motorist_Factor,
    Underinsured_Motorist_retention AS Underinsured_Motorist_Retention,
    Underinsured_Motorist_reason AS Underinsured_Motorist_Reason,
    Other_Than_Collision_method AS Other_Than_Collision_FactorMethod,
    Other_Than_Collision_amount AS Other_Than_Collision_Factor,
    Other_Than_Collision_retention AS Other_Than_Collision_Retention,
    Other_Than_Collision_reason AS Other_Than_Collision_Reason,
    Collision_method AS Collision_FactorMethod,
    Collision_amount AS Collision_Factor,
    Collision_retention AS Collision_Retention,
    Collision_reason AS Collision_Reason,
    Personal_Injury_Protection_method AS Personal_Injury_Protection_FactorMethod,
    Personal_Injury_Protection_amount AS Personal_Injury_Protection_Factor,
    Personal_Injury_Protection_retention AS Personal_Injury_Protection_Retention,
    Personal_Injury_Protection_reason AS Personal_Injury_Protection_Reason,
    Extended_Towing_and_Labor_method AS Extended_Towing_and_Labor_FactorMethod,
    Extended_Towing_and_Labor_amount AS Extended_Towing_and_Labor_Factor,
    Extended_Towing_and_Labor_retention AS Extended_Towing_and_Labor_Retention,
    Extended_Towing_and_Labor_reason AS Extended_Towing_and_Labor_Reason
FROM 
    (SELECT 
        Id,
        AccountTransactionVersionPremiumId,
        ObjectUniqueId,
        Coverage,
        CONCAT(lower(Coverage), '_', 
            CASE 
                WHEN Coverage = 'Bodily Injury' THEN 'method'
                WHEN Coverage = 'Property Damage' THEN 'method'
                WHEN Coverage = 'Medical Payments' THEN 'method'
                WHEN Coverage = 'Underinsured Motorist' THEN 'method'
                WHEN Coverage = 'Other Than Collision' THEN 'method'
                WHEN Coverage = 'Collision' THEN 'method'
                WHEN Coverage = 'Personal Injury Protection' THEN 'method'
                WHEN Coverage = 'Extended Towing and Labor' THEN 'method'
            END) AS MethodColumn,
        CONCAT(lower(Coverage), '_', 
            CASE 
                WHEN Coverage = 'Bodily Injury' THEN 'amount'
                WHEN Coverage = 'Property Damage' THEN 'amount'
                WHEN Coverage = 'Medical Payments' THEN 'amount'
                WHEN Coverage = 'Underinsured Motorist' THEN 'amount'
                WHEN Coverage = 'Other Than Collision' THEN 'amount'
                WHEN Coverage = 'Collision' THEN 'amount'
                WHEN Coverage = 'Personal Injury Protection' THEN 'amount'
                WHEN Coverage = 'Extended Towing and Labor' THEN 'amount'
            END) AS AmountColumn,
        CONCAT(lower(Coverage), '_', 'retention') AS RetentionColumn,
        CONCAT(lower(Coverage), '_', 'reason') AS ReasonColumn,
        Factor,
        FactorMethod AS method,
        Retention,
        Reason
    FROM 
        acctvpf 
    WHERE 
        Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor')) AS SourceTable
PIVOT 
(
    MAX(method) FOR MethodColumn IN (
        [bodily_injury_method], [property_damage_method], [medical_payments_method], [underinsured_motorist_method],
        [other_than_collision_method], [collision_method], [personal_injury_protection_method], [extended_towing_and_labor_method]
    )
) AS MethodPivot
PIVOT 
(
    MAX(Factor) FOR AmountColumn IN (
        [bodily_injury_amount], [property_damage_amount], [medical_payments_amount], [underinsured_motorist_amount],
        [other_than_collision_amount], [collision_amount], [personal_injury_protection_amount], [extended_towing_and_labor_amount]
    )
) AS AmountPivot
PIVOT 
(
    MAX(Retention) FOR RetentionColumn IN (
        [bodily_injury_retention], [property_damage_retention], [medical_payments_retention], [underinsured_motorist_retention],
        [other_than_collision_retention], [collision_retention], [personal_injury_protection_retention], [extended_towing_and_labor_retention]
    )
) AS RetentionPivot
PIVOT 
(
    MAX(Reason) FOR ReasonColumn IN (
        [bodily_injury_reason], [property_damage_reason], [medical_payments_reason], [underinsured_motorist_reason],
        [other_than_collision_reason], [collision_reason], [personal_injury_protection_reason], [extended_towing_and_labor_reason]
    )
) AS ReasonPivot
;


select * from [edw_stage].[AccountTransactionVersionPremium];
select * from [edw_stage].[AccountTransactionVersionPremiumFactor];


select * 
FROM [edw_stage].[AccountTransactionVersion] AS acctv
INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
;

SELECT * FROM [edw_stage].[AccountTransactionVersionPremiumFactor];