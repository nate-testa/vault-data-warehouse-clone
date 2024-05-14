SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
-- ================================================================================================================================================
-- Description: This stored procedure inserts and updates info related to quote auto vehicle coverage - wip
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 05/06/24		Alberto Almario					1. Created the proc
-- 05/08/24		Architha Gudimalla				2. Updated @last_source_extract_ts
-- 05/14/24		Architha Gudimalla				3. Corrected errors
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_vehicle_coverage_wip]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		--************Start************

        -- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_vehicle_coverage_wip_temp1];

        WITH 
        acc AS (
            SELECT *
            FROM [edw_stage].[Account] AS a
            WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
            AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
            AND a.PolicyNumber IS NOT NULL
        )
        ,acctvpf AS (
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
            FROM acc
            INNER JOIN [edw_stage].[Product] p ON p.Id = acc.ProductId
            INNER JOIN [edw_stage].[AccountPremium] AS accp ON accp.AccountId = acc.id
            INNER JOIN [edw_stage].[AccountPremiumFactor] AS accpf ON accpf.AccountPremiumId = accp.id
            WHERE accpf.Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor')
            AND p.[Name] = 'Automobile'
            AND p.ProductLine = 'PersonalLines'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_amount') AS FinalColumnName, amount           as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, Number, ObjectUniqueId, CONCAT(FinalColumnName, '_reason') AS FinalColumnName, reason           as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )
        ,FinalTablePremAdj AS (
            SELECT
                PolicyNumber, EffectiveDate, Number
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
        )
        ,FinalTable AS (
            SELECT 
                CreatedDate, UpdatedDate, quote_no, effective_dt, vehicle_no, expiration_dt, 0 as transaction_seq_no, quote_history_sk, quote_auto_vehicle_sk, 
                [GaragingLocationId], [PrimaryParkingLocation], [DrivewaySecurity], [VehicleUsage], [DistanceToWork], [AnnualMiles], [LPMPFilingDate], [Ownership], [RegistrationStatus], [RegistrationDate], 
                [ExpirationDate], [RegisteredOwner], [RegisteredOwnerName], [ListedDriverName], [NonDriverName], [CompanyOtherEntityName], [RegistrationState], [RegistrationAddressLine1], 
                [RegistrationAddressLine2], [RegistrationAddressCity], [RegistrationAddressZipCode], [RegistrationAddressState], [SymbolBIPD], [SymbolPIPMED], 
                [SymbolOTC], [SymbolColl], [SymbolCostNewValue], [CostNew], [SymbolCostNew_ISO], [SymbolColl_ISO], [SymbolOTC_ISO], [SymbolBIPD_ISO], [SymbolPIPMED_ISO], 
                [OTCDeductible], [COLLDeductible], [FullGlass], [COLLType], [FireCoverage], [TheftCoverage], [UMPDCov], [UMPDLimit], [UMPDDeductible], [AgreedValue], [MarketValue], 
                [CustomizedEquipment], [ExtendedTowingAndLabor], [MotorcycleMEDLimits], [RatingTerritory], [OwnedVehicleDiscount], [HighPerformanceVehicleRating], [ExpenseLoadBI], [ExpenseLoadPD], 
                [ExpenseLoadPIP], [ExpenseLoadMED], [ExpenseLoadOTC], [ExpenseLoadCOLL], [ExpenseLoadUM], [BodilyInjuryNCRBPremium], [PropertyDamageNCRBPremium], [MedicalPaymentsNCRBPremium], 
                [UninsuredMotoristsBodilyInjuryNCRBPremium], [UninsuredMotoristsPropertyDamageNCRBPremium], [SendVehicleToLiabilityReporting], [AntiTheftDevice], [AntiLockBrakes], [PassiveRestraint], 
                [SeasonalUse], [DirectRepair], [CarStorageFacility], [VINEtching], [LossProtectionDiscount], [SeasonalUsePart2], [MarketAppreciationandDiminutionofValue], [VendorReportedWholesaleAmount],
                [BasicModelName],[DistributionDate],[Restraint],[FieldChangeIndicator],[FourWheelDriveIndicator],[ElectronicStabilityControl],[TonnageIndicator],[PayloadCapacity],
                [DaytimeRunningLightIndicator],[Wheelbase],[ClassCode],[AntiTheftIndicator],[GrossVehicleWeight],[StateException],[VMPerformanceIndicator],[NCICCode],[Chassis],[BaseMSRP],
                [SpecialHandlingIndicator],[RAPAInterimIndicator],[SpecialInfoSelector],[ModelSeriesInfo],[BodyInfo],[EngineInfo],[RestraintInfo],[TransmissionInfo],[OtherInfo],[ReleaseDate],
                [MotorHomeClass],[PassengerHazardExclusion],source_system_sk, vehicle_deleted_in, vehicle_unique_id
            
            FROM
                (
                    SELECT
                        acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, qav.[vehicle_no] as vehicle_no, acco.[UniqueId] as vehicle_unique_id,
                        acc.ExpirationDate as expiration_dt, --acc.Number as transaction_seq_no,
                        qh.quote_history_sk, qav.quote_auto_vehicle_sk, 
                        acco.IsdeletedOnPolicyChange as vehicle_deleted_in,
                        accof.[Field], accof.[Value],
                        CASE 
                            WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                            ELSE 4 --(Metal)
                        END as [source_system_sk]
                    FROM acc
                    INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                    INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                    INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                    LEFT JOIN [edw_core].[tquote_history] AS qh 
                        ON qh.quote_no = acc.PolicyNumber
                        AND qh.effective_dt = acc.EffectiveDate
                        AND qh.transaction_seq_no = 0
                    LEFT JOIN [edw_core].[tquote_auto_vehicle] AS qav
                        ON qav.quote_no = acc.PolicyNumber
                        AND qav.vehicle_no = acco.[Index]
                    WHERE
                        p.[Name] = 'Automobile'
                        AND p.ProductLine = 'PersonalLines'
                        AND accof.[Group] in ('Vehicle','Registration','Symbols','Symbols - ISO','Vehicle Coverages','AntiTheftDevice','Discounts','Surcharge','Security and Safety Features')
                ) t
            PIVOT 
                (
                    MAX([Value]) FOR [Field] IN 
                    (
                        [GaragingLocationId], [PrimaryParkingLocation], [DrivewaySecurity], [VehicleUsage], [DistanceToWork], [AnnualMiles], [LPMPFilingDate], [Ownership], [RegistrationStatus], [RegistrationDate], 
                        [ExpirationDate], [RegisteredOwner], [RegisteredOwnerName], [ListedDriverName], [NonDriverName], [CompanyOtherEntityName], [RegistrationState], [RegistrationAddressLine1], 
                        [RegistrationAddressLine2], [RegistrationAddressCity], [RegistrationAddressZipCode], [RegistrationAddressState], [SymbolBIPD], [SymbolPIPMED], 
                        [SymbolOTC], [SymbolColl], [SymbolCostNewValue], [CostNew], [SymbolCostNew_ISO], [SymbolColl_ISO], [SymbolOTC_ISO], [SymbolBIPD_ISO], [SymbolPIPMED_ISO], 
                        [OTCDeductible], [COLLDeductible], [FullGlass], [COLLType], [FireCoverage], [TheftCoverage], [UMPDCov], [UMPDLimit], [UMPDDeductible], [AgreedValue], [MarketValue], 
                        [CustomizedEquipment], [ExtendedTowingAndLabor], [MotorcycleMEDLimits], [RatingTerritory], [OwnedVehicleDiscount], [HighPerformanceVehicleRating], [ExpenseLoadBI], [ExpenseLoadPD], 
                        [ExpenseLoadPIP], [ExpenseLoadMED], [ExpenseLoadOTC], [ExpenseLoadCOLL], [ExpenseLoadUM], [BodilyInjuryNCRBPremium], [PropertyDamageNCRBPremium], [MedicalPaymentsNCRBPremium], 
                        [UninsuredMotoristsBodilyInjuryNCRBPremium], [UninsuredMotoristsPropertyDamageNCRBPremium], [SendVehicleToLiabilityReporting], [AntiTheftDevice], [AntiLockBrakes], [PassiveRestraint], 
                        [SeasonalUse], [DirectRepair], [CarStorageFacility], [VINEtching], [LossProtectionDiscount], [SeasonalUsePart2], [MarketAppreciationandDiminutionofValue], [VendorReportedWholesaleAmount],
                        [BasicModelName],[DistributionDate],[Restraint],[FieldChangeIndicator],[FourWheelDriveIndicator],[ElectronicStabilityControl],[TonnageIndicator],[PayloadCapacity],
                        [DaytimeRunningLightIndicator],[Wheelbase],[ClassCode],[AntiTheftIndicator],[GrossVehicleWeight],[StateException],[VMPerformanceIndicator],[NCICCode],[Chassis],[BaseMSRP],
                        [SpecialHandlingIndicator],[RAPAInterimIndicator],[SpecialInfoSelector],[ModelSeriesInfo],[BodyInfo],[EngineInfo],[RestraintInfo],[TransmissionInfo],[OtherInfo],[ReleaseDate],
                        [MotorHomeClass],[PassengerHazardExclusion]
                    )
                ) pivottable
        )

        SELECT 
            a.*
            ,b.bodily_injury_premium_adjustment_method
            ,b.bodily_injury_premium_adjustment_amount
            ,b.bodily_injury_premium_adjustment_retention
            ,b.bodily_injury_premium_adjustment_reason
            ,b.property_damage_premium_adjustment_method
            ,b.property_damage_premium_adjustment_amount
            ,b.property_damage_premium_adjustment_retention
            ,b.property_damage_premium_adjustment_reason
            ,b.medical_payments_premium_adjustment_method
            ,b.medical_payments_premium_adjustment_amount
            ,b.medical_payments_premium_adjustment_retention
            ,b.medical_payments_premium_adjustment_reason
            ,b.uninsured_motorist_premium_adjustment_method
            ,b.uninsured_motorist_premium_adjustment_amount
            ,b.uninsured_motorist_premium_adjustment_retention
            ,b.uninsured_motorist_premium_adjustment_reason
            ,b.other_than_collision_premium_adjustment_method
            ,b.other_than_collision_premium_adjustment_amount
            ,b.other_than_collision_premium_adjustment_retention
            ,b.other_than_collision_premium_adjustment_reason
            ,b.collision_premium_adjustment_method
            ,b.collision_premium_adjustment_amount
            ,b.collision_premium_adjustment_retention
            ,b.collision_premium_adjustment_reason
            ,b.personal_injury_protection_premium_adjustment_method
            ,b.personal_injury_protection_premium_adjustment_amount
            ,b.personal_injury_protection_premium_adjustment_retention
            ,b.personal_injury_protection_premium_adjustment_reason
            ,b.extended_towing_labor_premium_adjustment_method
            ,b.extended_towing_labor_premium_adjustment_amount
            ,b.extended_towing_labor_premium_adjustment_retention
            ,b.extended_towing_labor_premium_adjustment_reason
        INTO [edw_temp].[tquote_auto_vehicle_coverage_wip_temp1]
        FROM FinalTable AS a 
        LEFT JOIN FinalTablePremAdj AS b
        ON a.quote_no = b.PolicyNumber
        AND a.effective_dt = b.EffectiveDate
        AND a.transaction_seq_no = b.Number
        AND a.vehicle_unique_id = b.ObjectUniqueId



		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_vehicle_coverage] AS target
        USING (
            SELECT 
                t1.quote_no,
                t1.effective_dt,
                t1.vehicle_no,
                t1.expiration_dt,
                t1.transaction_seq_no,
                t1.quote_history_sk,
                t1.quote_auto_vehicle_sk,
                coalesce(gar.quote_auto_garage_location_sk, gar1.quote_auto_garage_location_sk) AS quote_auto_garage_location_sk,
                t1.[PrimaryParkingLocation] AS primary_parking_location,
                t1.[DrivewaySecurity] AS driveway_security,
                t1.[VehicleUsage] AS vehicle_usage,
                t1.[DistanceToWork] AS distance_to_work,
                t1.[AnnualMiles] AS annual_miles,
                t1.[LPMPFilingDate] AS lpmp_filing_dt,
                t1.[Ownership] AS vehicle_ownership,
                t1.[RegistrationStatus] AS registration_status,
                t1.[RegistrationDate] AS registration_dt,
                t1.[ExpirationDate] AS registration_expiration_dt,
                t1.[RegisteredOwner] AS registered_owner_type,
                t1.[RegisteredOwnerName] AS registered_owner_nm,
                t1.[ListedDriverName] AS listed_driver_nm,
                t1.[NonDriverName] AS non_driver_nm,
                t1.[CompanyOtherEntityName] AS company_other_entity_nm,
                t1.[RegistrationState] AS registration_state_cd,
                t1.[RegistrationAddressLine1] AS registration_address_line1,
                t1.[RegistrationAddressLine2] AS registration_address_line2,
                NULL AS registration_address_unit_no,
                t1.[RegistrationAddressCity] AS registration_address_city_nm,
                t1.[RegistrationAddressZipCode] AS registration_address_zip_cd,
                t1.[RegistrationAddressState] AS registration_address_state_nm,
                t1.[SymbolBIPD] AS symbol_bi_pd,
                t1.[SymbolPIPMED] AS symbol_pip_med,
                t1.[SymbolOTC] AS symbol_otc,
                t1.[SymbolColl] AS symbol_coll,
                t1.[SymbolCostNewValue] AS symbol_cost_new_amt,
                t1.[CostNew] AS motorcycle_cost_new_amt,
                t1.[SymbolCostNew_ISO] AS symbol_cost_new_iso,
                t1.[SymbolColl_ISO] AS symbol_coll_iso,
                t1.[SymbolOTC_ISO] AS symbol_otc_iso,
                t1.[SymbolBIPD_ISO] AS symbol_bi_pd_iso,
                t1.[SymbolPIPMED_ISO] AS symbol_pip_med_iso,
                t1.[OTCDeductible] AS otc_deductible,
                t1.[COLLDeductible] AS collision_deductible,
                t1.[FullGlass] AS full_glass_coverage_in,
                t1.[COLLType] AS collision_type,
                t1.[FireCoverage] AS fire_coverage_in,
                t1.[TheftCoverage] AS theft_coverage_in,
                t1.[UMPDCov] AS umpd_coverage_in,
                t1.[UMPDLimit] AS umpd_limit_amt,
                t1.[UMPDDeductible] AS umpd_deductible,
                t1.[AgreedValue] AS agreed_value_amt,
                t1.[MarketValue] AS market_value_amt,
                t1.[CustomizedEquipment] AS customized_equipment_value_amt,
                t1.[ExtendedTowingAndLabor] AS extended_towing_and_labor_in,
                t1.[MotorcycleMEDLimits] AS motorcycle_med_limit_amt,
                t1.[RatingTerritory] AS rating_territory_cd,
                t1.[OwnedVehicleDiscount] AS owned_vehicle_discount_in,
                t1.[HighPerformanceVehicleRating] AS high_performance_vehicle_rating,
                t1.[ExpenseLoadBI] AS bodily_injury_expense_load,
                t1.[ExpenseLoadPD] AS property_damage_expense_load,
                t1.[ExpenseLoadPIP] AS pip_expense_load,
                t1.[ExpenseLoadMED] AS medical_expense_load,
                t1.[ExpenseLoadOTC] AS otc_expense_load,
                t1.[ExpenseLoadCOLL] AS collision_expense_load,
                t1.[ExpenseLoadUM] AS uninsured_motorist_expense_load,
                t1.[BodilyInjuryNCRBPremium] AS bodily_injury_ncrb_premium_amt,
                t1.[PropertyDamageNCRBPremium] AS property_damage_ncrb_premium_amt,
                t1.[MedicalPaymentsNCRBPremium] AS medical_payments_ncrb_premium_amt,
                t1.[UninsuredMotoristsBodilyInjuryNCRBPremium] AS uninsured_motorist_bodily_injury_ncrb_premium_amt,
                t1.[UninsuredMotoristsPropertyDamageNCRBPremium] AS uninsured_motorist_property_damage_ncrb_premium_amt,
                t1.[SendVehicleToLiabilityReporting] AS send_vehicle_to_liability_reporting_in,
                CASE 
                    WHEN t1.[AntiTheftDevice] = 'Active' THEN 'Active - a disabling device that much be activated by the operator'
                    WHEN t1.[AntiTheftDevice] = 'Passive' THEN 'Passive - a disabling device that is automatically activated when the car is parked'
                    WHEN t1.[AntiTheftDevice] = 'Recovery' THEN 'Recovery - an active vehicle recovery system'
                    WHEN t1.[AntiTheftDevice] = 'Category1' THEN 'Category 1 (Ignition Cut Off, Active External Alarms, etc.)'
                    WHEN t1.[AntiTheftDevice] = 'Category2' THEN 'Category 2 (Active Fuel Cut Off, Wheel Lock, Emergency Handbrake Locks, Transmission Locks, etc.)'
                    WHEN t1.[AntiTheftDevice] = 'Category3' THEN 'Category 3 (Passive Alarm Systems, Passive Fuel Locks, etc.)'
                    WHEN t1.[AntiTheftDevice] = 'Category4' THEN 'Category 4 (Recovery Devices Including GPS Tracking)'
                    WHEN t1.[AntiTheftDevice] = 'Category3And4' THEN 'Categories 3 & 4'
                    WHEN t1.[AntiTheftDevice] = '' THEN NULL
                    ELSE t1.[AntiTheftDevice]
                END AS antitheft_device_feature,
                t1.[AntiLockBrakes] AS antilock_brake_in,
                t1.[PassiveRestraint] AS passive_restraint_in,
                t1.[SeasonalUse] AS seasonal_use_in,
                t1.[DirectRepair] AS direct_repair_in,
                t1.[CarStorageFacility] AS car_storage_facility_in,
                t1.[VINEtching] AS vin_etching_in,
                t1.[LossProtectionDiscount] AS loss_protection_discount_in,
                t1.[SeasonalUsePart2] AS seasonal_use_part2_in,
                t1.[MarketAppreciationandDiminutionofValue] AS market_appreciation_diminution_of_value_in,
                t1.source_system_sk,
                GETDATE() AS create_ts,
                GETDATE() AS update_ts,
                @etl_audit_sk AS etl_audit_sk,
                CASE 
                    WHEN t1.vehicle_deleted_in = 1 THEN 'Yes' 
                    ELSE 'No' 
                END AS vehicle_deleted_in,
                t1.[VendorReportedWholesaleAmount] AS carfax_wholesale_value_amt,
                t1.[BasicModelName] AS basic_model_nm,
                t1.[DistributionDate] AS vehicle_distribution_dt,
                t1.[Restraint] AS vehicle_restraint,
                t1.[FieldChangeIndicator] AS field_change_in,
                t1.[FourWheelDriveIndicator] AS four_wheel_drive_in,
                t1.[ElectronicStabilityControl] AS electronic_stability_control,
                t1.[TonnageIndicator] AS tonnage_in,
                t1.[PayloadCapacity] AS payload_capacity,
                t1.[DaytimeRunningLightIndicator] AS daytime_running_light_in,
                t1.[Wheelbase] AS wheel_base,
                t1.[ClassCode] AS class_cd,
                t1.[AntiTheftIndicator] AS antitheft_in,
                t1.[GrossVehicleWeight] AS vehicle_gross_weight,
                t1.[StateException] AS state_exception,
                t1.[VMPerformanceIndicator] AS vm_performance_in,
                t1.[NCICCode] AS ncic_cd,
                t1.[Chassis] AS vehicle_chassis,
                t1.[BaseMSRP] AS base_msrp,
                t1.[SpecialHandlingIndicator] AS special_handling_in,
                t1.[RAPAInterimIndicator] AS rapa_interim_in,
                t1.[SpecialInfoSelector] AS special_info_selector,
                t1.[ModelSeriesInfo] AS model_series_info,
                t1.[BodyInfo] AS vehicle_body_info,
                t1.[EngineInfo] AS vehicle_engine_info,
                t1.[RestraintInfo] AS restraint_info,
                t1.[TransmissionInfo] AS transmission_info,
                t1.[OtherInfo] AS other_info,
                t1.[ReleaseDate] AS vehicle_release_dt,
                t1.[MotorHomeClass] AS motor_home_class,
                t1.[PassengerHazardExclusion] AS passenger_hazard_exclusion_in,
                t1.bodily_injury_premium_adjustment_method,
                t1.bodily_injury_premium_adjustment_amount,
                t1.bodily_injury_premium_adjustment_retention,
                t1.bodily_injury_premium_adjustment_reason,
                t1.property_damage_premium_adjustment_method,
                t1.property_damage_premium_adjustment_amount,
                t1.property_damage_premium_adjustment_retention,
                t1.property_damage_premium_adjustment_reason,
                t1.medical_payments_premium_adjustment_method,
                t1.medical_payments_premium_adjustment_amount,
                t1.medical_payments_premium_adjustment_retention,
                t1.medical_payments_premium_adjustment_reason,
                t1.uninsured_motorist_premium_adjustment_method,
                t1.uninsured_motorist_premium_adjustment_amount,
                t1.uninsured_motorist_premium_adjustment_retention,
                t1.uninsured_motorist_premium_adjustment_reason,
                t1.other_than_collision_premium_adjustment_method,
                t1.other_than_collision_premium_adjustment_amount,
                t1.other_than_collision_premium_adjustment_retention,
                t1.other_than_collision_premium_adjustment_reason,
                t1.collision_premium_adjustment_method,
                t1.collision_premium_adjustment_amount,
                t1.collision_premium_adjustment_retention,
                t1.collision_premium_adjustment_reason,
                t1.personal_injury_protection_premium_adjustment_method,
                t1.personal_injury_protection_premium_adjustment_amount,
                t1.personal_injury_protection_premium_adjustment_retention,
                t1.personal_injury_protection_premium_adjustment_reason,
                t1.extended_towing_labor_premium_adjustment_method,
                t1.extended_towing_labor_premium_adjustment_amount,
                t1.extended_towing_labor_premium_adjustment_retention,
                t1.extended_towing_labor_premium_adjustment_reason
            FROM 
                [edw_temp].[tquote_auto_vehicle_coverage_wip_temp1] AS t1
            LEFT JOIN 
                [edw_stage].[AccountObject] AS ao ON ao.id = t1.GaragingLocationId
            LEFT JOIN 
                [edw_core].[tquote_auto_garage_location] AS gar ON gar.quote_no = t1.quote_no AND gar.effective_dt = t1.effective_dt AND gar.transaction_seq_no = t1.transaction_seq_no AND gar.garage_location_no = ao.[Index]
            LEFT JOIN (
                SELECT 
                    RANK() OVER (PARTITION BY quote_no, effective_dt, transaction_seq_no ORDER BY quote_no, effective_dt, transaction_seq_no, garage_location_no) AS rnk, 
                    *
                FROM 
                    [edw_core].[tquote_auto_garage_location]
            ) gar1 ON gar1.rnk = 1 AND gar1.quote_no = t1.quote_no AND gar1.effective_dt = t1.effective_dt AND t1.transaction_seq_no = gar1.transaction_seq_no
        ) AS source 
            ON target.quote_no = source.quote_no 
            AND target.effective_dt = source.effective_dt 
            AND target.vehicle_no = source.vehicle_no 
            AND target.transaction_seq_no = source.transaction_seq_no
        WHEN MATCHED THEN
            UPDATE SET 
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.quote_auto_vehicle_sk = source.quote_auto_vehicle_sk,
                target.quote_auto_garage_location_sk = source.quote_auto_garage_location_sk,
                target.primary_parking_location = source.primary_parking_location,
                target.driveway_security = source.driveway_security,
                target.vehicle_usage = source.vehicle_usage,
                target.distance_to_work = source.distance_to_work,
                target.annual_miles = source.annual_miles,
                target.lpmp_filing_dt = source.lpmp_filing_dt,
                target.vehicle_ownership = source.vehicle_ownership,
                target.registration_status = source.registration_status,
                target.registration_dt = source.registration_dt,
                target.registration_expiration_dt = source.registration_expiration_dt,
                target.registered_owner_type = source.registered_owner_type,
                target.registered_owner_nm = source.registered_owner_nm,
                target.listed_driver_nm = source.listed_driver_nm,
                target.non_driver_nm = source.non_driver_nm,
                target.company_other_entity_nm = source.company_other_entity_nm,
                target.registration_state_cd = source.registration_state_cd,
                target.registration_address_line1 = source.registration_address_line1,
                target.registration_address_line2 = source.registration_address_line2,
                target.registration_address_unit_no = source.registration_address_unit_no,
                target.registration_address_city_nm = source.registration_address_city_nm,
                target.registration_address_zip_cd = source.registration_address_zip_cd,
                target.registration_address_state_nm = source.registration_address_state_nm,
                target.symbol_bi_pd = source.symbol_bi_pd,
                target.symbol_pip_med = source.symbol_pip_med,
                target.symbol_otc = source.symbol_otc,
                target.symbol_coll = source.symbol_coll,
                target.symbol_cost_new_amt = source.symbol_cost_new_amt,
                target.motorcycle_cost_new_amt = source.motorcycle_cost_new_amt,
                target.symbol_cost_new_iso = source.symbol_cost_new_iso,
                target.symbol_coll_iso = source.symbol_coll_iso,
                target.symbol_otc_iso = source.symbol_otc_iso,
                target.symbol_bi_pd_iso = source.symbol_bi_pd_iso,
                target.symbol_pip_med_iso = source.symbol_pip_med_iso,
                target.otc_deductible = source.otc_deductible,
                target.collision_deductible = source.collision_deductible,
                target.full_glass_coverage_in = source.full_glass_coverage_in,
                target.collision_type = source.collision_type,
                target.fire_coverage_in = source.fire_coverage_in,
                target.theft_coverage_in = source.theft_coverage_in,
                target.umpd_coverage_in = source.umpd_coverage_in,
                target.umpd_limit_amt = source.umpd_limit_amt,
                target.umpd_deductible = source.umpd_deductible,
                target.agreed_value_amt = source.agreed_value_amt,
                target.market_value_amt = source.market_value_amt,
                target.customized_equipment_value_amt = source.customized_equipment_value_amt,
                target.extended_towing_and_labor_in = source.extended_towing_and_labor_in,
                target.motorcycle_med_limit_amt = source.motorcycle_med_limit_amt,
                target.rating_territory_cd = source.rating_territory_cd,
                target.owned_vehicle_discount_in = source.owned_vehicle_discount_in,
                target.high_performance_vehicle_rating = source.high_performance_vehicle_rating,
                target.bodily_injury_expense_load = source.bodily_injury_expense_load,
                target.property_damage_expense_load = source.property_damage_expense_load,
                target.pip_expense_load = source.pip_expense_load,
                target.medical_expense_load = source.medical_expense_load,
                target.otc_expense_load = source.otc_expense_load,
                target.collision_expense_load = source.collision_expense_load,
                target.uninsured_motorist_expense_load = source.uninsured_motorist_expense_load,
                target.bodily_injury_ncrb_premium_amt = source.bodily_injury_ncrb_premium_amt,
                target.property_damage_ncrb_premium_amt = source.property_damage_ncrb_premium_amt,
                target.medical_payments_ncrb_premium_amt = source.medical_payments_ncrb_premium_amt,
                target.uninsured_motorist_bodily_injury_ncrb_premium_amt = source.uninsured_motorist_bodily_injury_ncrb_premium_amt,
                target.uninsured_motorist_property_damage_ncrb_premium_amt = source.uninsured_motorist_property_damage_ncrb_premium_amt,
                target.send_vehicle_to_liability_reporting_in = source.send_vehicle_to_liability_reporting_in,
                target.antitheft_device_feature = source.antitheft_device_feature,
                target.antilock_brake_in = source.antilock_brake_in,
                target.passive_restraint_in = source.passive_restraint_in,
                target.seasonal_use_in = source.seasonal_use_in,
                target.direct_repair_in = source.direct_repair_in,
                target.car_storage_facility_in = source.car_storage_facility_in,
                target.vin_etching_in = source.vin_etching_in,
                target.loss_protection_discount_in = source.loss_protection_discount_in,
                target.seasonal_use_part2_in = source.seasonal_use_part2_in,
                target.market_appreciation_diminution_of_value_in = source.market_appreciation_diminution_of_value_in,
                target.source_system_sk = source.source_system_sk,
                target.update_ts = GETDATE(),
                target.etl_audit_sk = @etl_audit_sk,
                target.vehicle_deleted_in = source.vehicle_deleted_in,
                target.carfax_wholesale_value_amt = source.carfax_wholesale_value_amt,
                target.basic_model_nm = source.basic_model_nm,
                target.vehicle_distribution_dt = source.vehicle_distribution_dt,
                target.vehicle_restraint = source.vehicle_restraint,
                target.field_change_in = source.field_change_in,
                target.four_wheel_drive_in = source.four_wheel_drive_in,
                target.electronic_stability_control = source.electronic_stability_control,
                target.tonnage_in = source.tonnage_in,
                target.payload_capacity = source.payload_capacity,
                target.daytime_running_light_in = source.daytime_running_light_in,
                target.wheel_base = source.wheel_base,
                target.class_cd = source.class_cd,
                target.antitheft_in = source.antitheft_in,
                target.vehicle_gross_weight = source.vehicle_gross_weight,
                target.state_exception = source.state_exception,
                target.vm_performance_in = source.vm_performance_in,
                target.ncic_cd = source.ncic_cd,
                target.vehicle_chassis = source.vehicle_chassis,
                target.base_msrp = source.base_msrp,
                target.special_handling_in = source.special_handling_in,
                target.rapa_interim_in = source.rapa_interim_in,
                target.special_info_selector = source.special_info_selector,
                target.model_series_info = source.model_series_info,
                target.vehicle_body_info = source.vehicle_body_info,
                target.vehicle_engine_info = source.vehicle_engine_info,
                target.restraint_info = source.restraint_info,
                target.transmission_info = source.transmission_info,
                target.other_info = source.other_info,
                target.vehicle_release_dt = source.vehicle_release_dt,
                target.motor_home_class = source.motor_home_class,
                target.passenger_hazard_exclusion_in = source.passenger_hazard_exclusion_in,
                target.bodily_injury_premium_adjustment_method = source.bodily_injury_premium_adjustment_method,
                target.bodily_injury_premium_adjustment_amount = source.bodily_injury_premium_adjustment_amount,
                target.bodily_injury_premium_adjustment_retention = source.bodily_injury_premium_adjustment_retention,
                target.bodily_injury_premium_adjustment_reason = source.bodily_injury_premium_adjustment_reason,
                target.property_damage_premium_adjustment_method = source.property_damage_premium_adjustment_method,
                target.property_damage_premium_adjustment_amount = source.property_damage_premium_adjustment_amount,
                target.property_damage_premium_adjustment_retention = source.property_damage_premium_adjustment_retention,
                target.property_damage_premium_adjustment_reason = source.property_damage_premium_adjustment_reason,
                target.medical_payments_premium_adjustment_method = source.medical_payments_premium_adjustment_method,
                target.medical_payments_premium_adjustment_amount = source.medical_payments_premium_adjustment_amount,
                target.medical_payments_premium_adjustment_retention = source.medical_payments_premium_adjustment_retention,
                target.medical_payments_premium_adjustment_reason = source.medical_payments_premium_adjustment_reason,
                target.uninsured_motorist_premium_adjustment_method = source.uninsured_motorist_premium_adjustment_method,
                target.uninsured_motorist_premium_adjustment_amount = source.uninsured_motorist_premium_adjustment_amount,
                target.uninsured_motorist_premium_adjustment_retention = source.uninsured_motorist_premium_adjustment_retention,
                target.uninsured_motorist_premium_adjustment_reason = source.uninsured_motorist_premium_adjustment_reason,
                target.other_than_collision_premium_adjustment_method = source.other_than_collision_premium_adjustment_method,
                target.other_than_collision_premium_adjustment_amount = source.other_than_collision_premium_adjustment_amount,
                target.other_than_collision_premium_adjustment_retention = source.other_than_collision_premium_adjustment_retention,
                target.other_than_collision_premium_adjustment_reason = source.other_than_collision_premium_adjustment_reason,
                target.collision_premium_adjustment_method = source.collision_premium_adjustment_method,
                target.collision_premium_adjustment_amount = source.collision_premium_adjustment_amount,
                target.collision_premium_adjustment_retention = source.collision_premium_adjustment_retention,
                target.collision_premium_adjustment_reason = source.collision_premium_adjustment_reason,
                target.personal_injury_protection_premium_adjustment_method = source.personal_injury_protection_premium_adjustment_method,
                target.personal_injury_protection_premium_adjustment_amount = source.personal_injury_protection_premium_adjustment_amount,
                target.personal_injury_protection_premium_adjustment_retention = source.personal_injury_protection_premium_adjustment_retention,
                target.personal_injury_protection_premium_adjustment_reason = source.personal_injury_protection_premium_adjustment_reason,
                target.extended_towing_labor_premium_adjustment_method = source.extended_towing_labor_premium_adjustment_method,
                target.extended_towing_labor_premium_adjustment_amount = source.extended_towing_labor_premium_adjustment_amount,
                target.extended_towing_labor_premium_adjustment_retention = source.extended_towing_labor_premium_adjustment_retention,
                target.extended_towing_labor_premium_adjustment_reason = source.extended_towing_labor_premium_adjustment_reason
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no,
                effective_dt,
                vehicle_no,
                expiration_dt,
                transaction_seq_no,
                quote_history_sk,
                quote_auto_vehicle_sk,
                quote_auto_garage_location_sk,
                primary_parking_location,
                driveway_security,
                vehicle_usage,
                distance_to_work,
                annual_miles,
                lpmp_filing_dt,
                vehicle_ownership,
                registration_status,
                registration_dt,
                registration_expiration_dt,
                registered_owner_type,
                registered_owner_nm,
                listed_driver_nm,
                non_driver_nm,
                company_other_entity_nm,
                registration_state_cd,
                registration_address_line1,
                registration_address_line2,
                registration_address_unit_no,
                registration_address_city_nm,
                registration_address_zip_cd,
                registration_address_state_nm,
                symbol_bi_pd,
                symbol_pip_med,
                symbol_otc,
                symbol_coll,
                symbol_cost_new_amt,
                motorcycle_cost_new_amt,
                symbol_cost_new_iso,
                symbol_coll_iso,
                symbol_otc_iso,
                symbol_bi_pd_iso,
                symbol_pip_med_iso,
                otc_deductible,
                collision_deductible,
                full_glass_coverage_in,
                collision_type,
                fire_coverage_in,
                theft_coverage_in,
                umpd_coverage_in,
                umpd_limit_amt,
                umpd_deductible,
                agreed_value_amt,
                market_value_amt,
                customized_equipment_value_amt,
                extended_towing_and_labor_in,
                motorcycle_med_limit_amt,
                rating_territory_cd,
                owned_vehicle_discount_in,
                high_performance_vehicle_rating,
                bodily_injury_expense_load,
                property_damage_expense_load,
                pip_expense_load,
                medical_expense_load,
                otc_expense_load,
                collision_expense_load,
                uninsured_motorist_expense_load,
                bodily_injury_ncrb_premium_amt,
                property_damage_ncrb_premium_amt,
                medical_payments_ncrb_premium_amt,
                uninsured_motorist_bodily_injury_ncrb_premium_amt,
                uninsured_motorist_property_damage_ncrb_premium_amt,
                send_vehicle_to_liability_reporting_in,
                antitheft_device_feature,
                antilock_brake_in,
                passive_restraint_in,
                seasonal_use_in,
                direct_repair_in,
                car_storage_facility_in,
                vin_etching_in,
                loss_protection_discount_in,
                seasonal_use_part2_in,
                market_appreciation_diminution_of_value_in,
                source_system_sk,
                create_ts,
                update_ts,
                etl_audit_sk,
                vehicle_deleted_in,
                carfax_wholesale_value_amt,
                basic_model_nm,
                vehicle_distribution_dt,
                vehicle_restraint,
                field_change_in,
                four_wheel_drive_in,
                electronic_stability_control,
                tonnage_in,
                payload_capacity,
                daytime_running_light_in,
                wheel_base,
                class_cd,
                antitheft_in,
                vehicle_gross_weight,
                state_exception,
                vm_performance_in,
                ncic_cd,
                vehicle_chassis,
                base_msrp,
                special_handling_in,
                rapa_interim_in,
                special_info_selector,
                model_series_info,
                vehicle_body_info,
                vehicle_engine_info,
                restraint_info,
                transmission_info,
                other_info,
                vehicle_release_dt,
                motor_home_class,
                passenger_hazard_exclusion_in,
                bodily_injury_premium_adjustment_method,
                bodily_injury_premium_adjustment_amount,
                bodily_injury_premium_adjustment_retention,
                bodily_injury_premium_adjustment_reason,
                property_damage_premium_adjustment_method,
                property_damage_premium_adjustment_amount,
                property_damage_premium_adjustment_retention,
                property_damage_premium_adjustment_reason,
                medical_payments_premium_adjustment_method,
                medical_payments_premium_adjustment_amount,
                medical_payments_premium_adjustment_retention,
                medical_payments_premium_adjustment_reason,
                uninsured_motorist_premium_adjustment_method,
                uninsured_motorist_premium_adjustment_amount,
                uninsured_motorist_premium_adjustment_retention,
                uninsured_motorist_premium_adjustment_reason,
                other_than_collision_premium_adjustment_method,
                other_than_collision_premium_adjustment_amount,
                other_than_collision_premium_adjustment_retention,
                other_than_collision_premium_adjustment_reason,
                collision_premium_adjustment_method,
                collision_premium_adjustment_amount,
                collision_premium_adjustment_retention,
                collision_premium_adjustment_reason,
                personal_injury_protection_premium_adjustment_method,
                personal_injury_protection_premium_adjustment_amount,
                personal_injury_protection_premium_adjustment_retention,
                personal_injury_protection_premium_adjustment_reason,
                extended_towing_labor_premium_adjustment_method,
                extended_towing_labor_premium_adjustment_amount,
                extended_towing_labor_premium_adjustment_retention,
                extended_towing_labor_premium_adjustment_reason
            )
            VALUES (
                source.quote_no,
                source.effective_dt,
                source.vehicle_no,
                source.expiration_dt,
                source.transaction_seq_no,
                source.quote_history_sk,
                source.quote_auto_vehicle_sk,
                source.quote_auto_garage_location_sk,
                source.primary_parking_location,
                source.driveway_security,
                source.vehicle_usage,
                source.distance_to_work,
                source.annual_miles,
                source.lpmp_filing_dt,
                source.vehicle_ownership,
                source.registration_status,
                source.registration_dt,
                source.registration_expiration_dt,
                source.registered_owner_type,
                source.registered_owner_nm,
                source.listed_driver_nm,
                source.non_driver_nm,
                source.company_other_entity_nm,
                source.registration_state_cd,
                source.registration_address_line1,
                source.registration_address_line2,
                source.registration_address_unit_no,
                source.registration_address_city_nm,
                source.registration_address_zip_cd,
                source.registration_address_state_nm,
                source.symbol_bi_pd,
                source.symbol_pip_med,
                source.symbol_otc,
                source.symbol_coll,
                source.symbol_cost_new_amt,
                source.motorcycle_cost_new_amt,
                source.symbol_cost_new_iso,
                source.symbol_coll_iso,
                source.symbol_otc_iso,
                source.symbol_bi_pd_iso,
                source.symbol_pip_med_iso,
                source.otc_deductible,
                source.collision_deductible,
                source.full_glass_coverage_in,
                source.collision_type,
                source.fire_coverage_in,
                source.theft_coverage_in,
                source.umpd_coverage_in,
                source.umpd_limit_amt,
                source.umpd_deductible,
                source.agreed_value_amt,
                source.market_value_amt,
                source.customized_equipment_value_amt,
                source.extended_towing_and_labor_in,
                source.motorcycle_med_limit_amt,
                source.rating_territory_cd,
                source.owned_vehicle_discount_in,
                source.high_performance_vehicle_rating,
                source.bodily_injury_expense_load,
                source.property_damage_expense_load,
                source.pip_expense_load,
                source.medical_expense_load,
                source.otc_expense_load,
                source.collision_expense_load,
                source.uninsured_motorist_expense_load,
                source.bodily_injury_ncrb_premium_amt,
                source.property_damage_ncrb_premium_amt,
                source.medical_payments_ncrb_premium_amt,
                source.uninsured_motorist_bodily_injury_ncrb_premium_amt,
                source.uninsured_motorist_property_damage_ncrb_premium_amt,
                source.send_vehicle_to_liability_reporting_in,
                source.antitheft_device_feature,
                source.antilock_brake_in,
                source.passive_restraint_in,
                source.seasonal_use_in,
                source.direct_repair_in,
                source.car_storage_facility_in,
                source.vin_etching_in,
                source.loss_protection_discount_in,
                source.seasonal_use_part2_in,
                source.market_appreciation_diminution_of_value_in,
                source.source_system_sk,
                GETDATE(),
                GETDATE(),
                @etl_audit_sk,
                source.vehicle_deleted_in,
                source.carfax_wholesale_value_amt,
                source.basic_model_nm,
                source.vehicle_distribution_dt,
                source.vehicle_restraint,
                source.field_change_in,
                source.four_wheel_drive_in,
                source.electronic_stability_control,
                source.tonnage_in,
                source.payload_capacity,
                source.daytime_running_light_in,
                source.wheel_base,
                source.class_cd,
                source.antitheft_in,
                source.vehicle_gross_weight,
                source.state_exception,
                source.vm_performance_in,
                source.ncic_cd,
                source.vehicle_chassis,
                source.base_msrp,
                source.special_handling_in,
                source.rapa_interim_in,
                source.special_info_selector,
                source.model_series_info,
                source.vehicle_body_info,
                source.vehicle_engine_info,
                source.restraint_info,
                source.transmission_info,
                source.other_info,
                source.vehicle_release_dt,
                source.motor_home_class,
                source.passenger_hazard_exclusion_in,
                source.bodily_injury_premium_adjustment_method,
                source.bodily_injury_premium_adjustment_amount,
                source.bodily_injury_premium_adjustment_retention,
                source.bodily_injury_premium_adjustment_reason,
                source.property_damage_premium_adjustment_method,
                source.property_damage_premium_adjustment_amount,
                source.property_damage_premium_adjustment_retention,
                source.property_damage_premium_adjustment_reason,
                source.medical_payments_premium_adjustment_method,
                source.medical_payments_premium_adjustment_amount,
                source.medical_payments_premium_adjustment_retention,
                source.medical_payments_premium_adjustment_reason,
                source.uninsured_motorist_premium_adjustment_method,
                source.uninsured_motorist_premium_adjustment_amount,
                source.uninsured_motorist_premium_adjustment_retention,
                source.uninsured_motorist_premium_adjustment_reason,
                source.other_than_collision_premium_adjustment_method,
                source.other_than_collision_premium_adjustment_amount,
                source.other_than_collision_premium_adjustment_retention,
                source.other_than_collision_premium_adjustment_reason,
                source.collision_premium_adjustment_method,
                source.collision_premium_adjustment_amount,
                source.collision_premium_adjustment_retention,
                source.collision_premium_adjustment_reason,
                source.personal_injury_protection_premium_adjustment_method,
                source.personal_injury_protection_premium_adjustment_amount,
                source.personal_injury_protection_premium_adjustment_retention,
                source.personal_injury_protection_premium_adjustment_reason,
                source.extended_towing_labor_premium_adjustment_method,
                source.extended_towing_labor_premium_adjustment_amount,
                source.extended_towing_labor_premium_adjustment_retention,
                source.extended_towing_labor_premium_adjustment_reason
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(CreatedDate,UpdatedDate)) FROM edw_temp.[tquote_auto_vehicle_coverage_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_vehicle_coverage_wip_temp1];

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	
    END CATCH
END
GO
