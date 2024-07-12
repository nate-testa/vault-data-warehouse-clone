SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-11
-- Description: This stored procedure insert and update info related to tauto_vehicle_coverage.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 11/06/23		Alberto Almario					1. change to use UniqueId instead of Index and change name from vehicle_no to vehicle_unique_id
-- 11/07/23     Sandeep Gundreddy               2. Added logic to get max auto_garage_location_sk
-- 11/16/23     Architha Gudimalla              3. Updated logic for auto_garage_location_sk
-- 02/22/24     Architha Gudimalla              4. Added Security and Safety Features in the acctvof group
-- 02/22/24     Hernando Gonzalez               5. Added new fields carfax_wholesale_value_amt
-- 02/27/24     Architha Gudimalla              6. Added case for antitheft
-- 02/04/24     Alberto Almario                 7. add 62 new columns
-- 13/06/24     Hernando Gonzalez               8. Added NewlyPurchasedVehicleFinal
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_vehicle_coverage]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp1];
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp2];
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp3];

        WITH 
        acctvpf AS (
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
            AND acct.IssuedDate > @last_source_extract_ts
            AND acctvpf.Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor')
            AND p.[Name] = 'Automobile'
            AND p.ProductLine = 'PersonalLines'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, ObjectUniqueId, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, ObjectUniqueId, CONCAT(FinalColumnName, '_amount') AS FinalColumnName, amount           as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, ObjectUniqueId, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, ObjectUniqueId, CONCAT(FinalColumnName, '_reason') AS FinalColumnName, reason           as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )
        

        SELECT
            PolicyNumber, EffectiveDate, IssuedDate, policychangenumber
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
        INTO [edw_temp].[tauto_vehicle_coverage_temp2]
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


        SELECT 
            IssuedDate, policy_no, effective_dt, vehicle_no, vehicle_unique_id, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, policy_history_sk, auto_vehicle_sk, auto_garage_location_sk,
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
            [MotorHomeClass],[PassengerHazardExclusion],source_system_sk, vehicle_deleted_in, [NewlyPurchasedVehicle], [NewlyPurchasedVehicleDate], [NewlyPurchasedVehicleFinal]
        INTO [edw_temp].[tauto_vehicle_coverage_temp3]
        FROM
            (
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, av.[vehicle_no] as vehicle_no, [UniqueId] as vehicle_unique_id, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                    ph.policy_history_sk, av.auto_vehicle_sk, 0 auto_garage_location_sk, 
                    acctvo.IsdeletedOnPolicyChange as vehicle_deleted_in,
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM [edw_stage].[AccountTransaction] AS acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                    ON ph.policy_no = acct.PolicyNumber
                    AND ph.effective_dt = acct.EffectiveDate
                    AND ph.transaction_seq_no = acct.policychangenumber
                LEFT JOIN [edw_core].[tauto_vehicle] AS av
                    ON av.policy_no = acct.PolicyNumber
                    AND av.effective_dt = acct.EffectiveDate
                    AND av.vehicle_unique_id = acctvo.[UniqueId]
                WHERE acct.[State] = 'ISSUED'
                    AND acct.IssuedDate > @last_source_extract_ts
                    AND p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Vehicle','Registration','Symbols','Symbols - ISO','Vehicle Coverages','AntiTheftDevice','Discounts','Surcharge','Security and Safety Features')
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
                    [MotorHomeClass],[PassengerHazardExclusion], [NewlyPurchasedVehicle], [NewlyPurchasedVehicleDate], [NewlyPurchasedVehicleFinal]
                )
            ) pivottable


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
        INTO [edw_temp].[tauto_vehicle_coverage_temp1]
        FROM [edw_temp].[tauto_vehicle_coverage_temp3] AS a 
        LEFT JOIN [edw_temp].[tauto_vehicle_coverage_temp2] AS b
        ON a.policy_no = b.PolicyNumber
        AND a.effective_dt = b.EffectiveDate
        AND a.IssuedDate = b.IssuedDate
        AND a.transaction_seq_no = b.policychangenumber
        AND a.vehicle_unique_id = b.ObjectUniqueId

        

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_vehicle_coverage]
        (
            policy_no,
            effective_dt,
            vehicle_no,
            transaction_effective_dt,
            expiration_dt,
            transaction_dt,
            transaction_seq_no,
            policy_history_sk,
            auto_vehicle_sk,
            auto_garage_location_sk,
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
            vehicle_unique_id,
            carfax_wholesale_value_amt
            ,basic_model_nm
            ,vehicle_distribution_dt
            ,vehicle_restraint
            ,field_change_in
            ,four_wheel_drive_in
            ,electronic_stability_control
            ,tonnage_in
            ,payload_capacity
            ,daytime_running_light_in
            ,wheel_base
            ,class_cd
            ,antitheft_in
            ,vehicle_gross_weight
            ,state_exception
            ,vm_performance_in
            ,ncic_cd
            ,vehicle_chassis
            ,base_msrp
            ,special_handling_in
            ,rapa_interim_in
            ,special_info_selector
            ,model_series_info
            ,vehicle_body_info
            ,vehicle_engine_info
            ,restraint_info
            ,transmission_info
            ,other_info
            ,vehicle_release_dt
            ,motor_home_class
            ,passenger_hazard_exclusion_in
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
            ,newly_purchased_vehicle_override_in
            ,newly_purchased_vehicle_dt
            ,newly_purchased_vehicle_final_in
		)
        SELECT 
            t1.policy_no,
            t1.effective_dt,
            t1.vehicle_no,
            t1.transaction_effective_dt,
            t1.expiration_dt,
            t1.transaction_dt,
            t1.transaction_seq_no,
            t1.policy_history_sk,
            t1.auto_vehicle_sk, 
            coalesce(gar.auto_garage_location_sk,gar1.auto_garage_location_sk) as auto_garage_location_sk,
            t1.[PrimaryParkingLocation] as primary_parking_location,
            t1.[DrivewaySecurity] as driveway_security,
            t1.[VehicleUsage] as vehicle_usage,
            t1.[DistanceToWork] as distance_to_work,
            t1.[AnnualMiles] as annual_miles,
            t1.[LPMPFilingDate] as lpmp_filing_dt,
            t1.[Ownership] as vehicle_ownership,
            t1.[RegistrationStatus] as registration_status,
            t1.[RegistrationDate] as registration_dt,
            t1.[ExpirationDate] as registration_expiration_dt,
            t1.[RegisteredOwner] as registered_owner_type,
            t1.[RegisteredOwnerName] as registered_owner_nm,
            t1.[ListedDriverName] as listed_driver_nm,
            t1.[NonDriverName] as non_driver_nm,
            t1.[CompanyOtherEntityName] as company_other_entity_nm,
            t1.[RegistrationState] as registration_state_cd,
            t1.[RegistrationAddressLine1] as registration_address_line1,
            t1.[RegistrationAddressLine2] as registration_address_line2,
            NULL as registration_address_unit_no,
            t1.[RegistrationAddressCity] as registration_address_city_nm,
            t1.[RegistrationAddressZipCode] as registration_address_zip_cd,
            t1.[RegistrationAddressState] as registration_address_state_nm,
            t1.[SymbolBIPD] as symbol_bi_pd,
            t1.[SymbolPIPMED] as symbol_pip_med,
            t1.[SymbolOTC] as symbol_otc,
            t1.[SymbolColl] as symbol_coll,
            t1.[SymbolCostNewValue] as symbol_cost_new_amt,
            t1.[CostNew] as motorcycle_cost_new_amt,
            t1.[SymbolCostNew_ISO] as symbol_cost_new_iso,
            t1.[SymbolColl_ISO] as symbol_coll_iso,
            t1.[SymbolOTC_ISO] as symbol_otc_iso,
            t1.[SymbolBIPD_ISO] as symbol_bi_pd_iso,
            t1.[SymbolPIPMED_ISO] as symbol_pip_med_iso,
            t1.[OTCDeductible] as otc_deductible,
            t1.[COLLDeductible] as collision_deductible,
            t1.[FullGlass] as full_glass_coverage_in,
            t1.[COLLType] as collision_type,
            t1.[FireCoverage] as fire_coverage_in,
            t1.[TheftCoverage] as theft_coverage_in,
            t1.[UMPDCov] as umpd_coverage_in,
            t1.[UMPDLimit] as umpd_limit_amt,
            t1.[UMPDDeductible] as umpd_deductible,
            t1.[AgreedValue] as agreed_value_amt,
            t1.[MarketValue] as market_value_amt,
            t1.[CustomizedEquipment] as customized_equipment_value_amt,
            t1.[ExtendedTowingAndLabor] as extended_towing_and_labor_in,
            t1.[MotorcycleMEDLimits] as motorcycle_med_limit_amt,
            t1.[RatingTerritory] as rating_territory_cd,
            t1.[OwnedVehicleDiscount] as owned_vehicle_discount_in,
            t1.[HighPerformanceVehicleRating] as high_performance_vehicle_rating,
            t1.[ExpenseLoadBI] as bodily_injury_expense_load,
            t1.[ExpenseLoadPD] as property_damage_expense_load,
            t1.[ExpenseLoadPIP] as pip_expense_load,
            t1.[ExpenseLoadMED] as medical_expense_load,
            t1.[ExpenseLoadOTC] as otc_expense_load,
            t1.[ExpenseLoadCOLL] as collision_expense_load,
            t1.[ExpenseLoadUM] as uninsured_motorist_expense_load,
            t1.[BodilyInjuryNCRBPremium] as bodily_injury_ncrb_premium_amt,
            t1.[PropertyDamageNCRBPremium] as property_damage_ncrb_premium_amt,
            t1.[MedicalPaymentsNCRBPremium] as medical_payments_ncrb_premium_amt,
            t1.[UninsuredMotoristsBodilyInjuryNCRBPremium] as uninsured_motorist_bodily_injury_ncrb_premium_amt,
            t1.[UninsuredMotoristsPropertyDamageNCRBPremium] as uninsured_motorist_property_damage_ncrb_premium_amt,
            t1.[SendVehicleToLiabilityReporting] as send_vehicle_to_liability_reporting_in,
            case	when t1.[AntiTheftDevice] = 'Active' then 'Active - a disabling device that much be activated by the operator'
                    when t1.[AntiTheftDevice] = 'Passive' then 'Passive - a disabling device that is automatically activated when the car is parked'
                    when t1.[AntiTheftDevice] = 'Recovery' then 'Recovery - an active vehicle recovery system'
                    when t1.[AntiTheftDevice] = 'Category1' then 'Category 1 (Ignition Cut Off, Active External Alarms, etc.)'
                    when t1.[AntiTheftDevice] = 'Category2' then 'Category 2 (Active Fuel Cut Off, Wheel Lock, Emergency Handbrake Locks, Transmission Locks, etc.)'
                    when t1.[AntiTheftDevice] = 'Category3' then 'Category 3 (Passive Alarm Systems, Passive Fuel Locks, etc.)'
                    when t1.[AntiTheftDevice] = 'Category4' then 'Category 4 (Recovery Devices Including GPS Tracking)'
                    when t1.[AntiTheftDevice] = 'Category3And4' then 'Categories 3 & 4'
                    when t1.[AntiTheftDevice] = '' then Null
            else t1.[AntiTheftDevice]
            end as antitheft_device_feature,
            t1.[AntiLockBrakes] as antilock_brake_in,
            t1.[PassiveRestraint] as passive_restraint_in,
            t1.[SeasonalUse] as seasonal_use_in,
            t1.[DirectRepair] as direct_repair_in,
            t1.[CarStorageFacility] as car_storage_facility_in,
            t1.[VINEtching] as vin_etching_in,
            t1.[LossProtectionDiscount] as loss_protection_discount_in,
            t1.[SeasonalUsePart2] as seasonal_use_part2_in,
            t1.[MarketAppreciationandDiminutionofValue] as market_appreciation_diminution_of_value_in,
            t1.source_system_sk,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE WHEN t1.vehicle_deleted_in = 1 THEN 'Yes' ELSE 'No' END as vehicle_deleted_in,
            t1.vehicle_unique_id,
            t1.[VendorReportedWholesaleAmount] as carfax_wholesale_value_amt
            ,t1.[BasicModelName] as basic_model_nm
            ,t1.[DistributionDate] as vehicle_distribution_dt
            ,t1.[Restraint] as vehicle_restraint
            ,t1.[FieldChangeIndicator] as field_change_in
            ,t1.[FourWheelDriveIndicator] as four_wheel_drive_in
            ,t1.[ElectronicStabilityControl] as electronic_stability_control
            ,t1.[TonnageIndicator] as tonnage_in
            ,t1.[PayloadCapacity] as payload_capacity
            ,t1.[DaytimeRunningLightIndicator] as daytime_running_light_in
            ,t1.[Wheelbase] as wheel_base
            ,t1.[ClassCode] as class_cd
            ,t1.[AntiTheftIndicator] as antitheft_in
            ,t1.[GrossVehicleWeight] as vehicle_gross_weight
            ,t1.[StateException] as state_exception
            ,t1.[VMPerformanceIndicator] as vm_performance_in
            ,t1.[NCICCode] as ncic_cd
            ,t1.[Chassis] as vehicle_chassis
            ,t1.[BaseMSRP] as base_msrp
            ,t1.[SpecialHandlingIndicator] as special_handling_in
            ,t1.[RAPAInterimIndicator] as rapa_interim_in
            ,t1.[SpecialInfoSelector] as special_info_selector
            ,t1.[ModelSeriesInfo] as model_series_info
            ,t1.[BodyInfo] as vehicle_body_info
            ,t1.[EngineInfo] as vehicle_engine_info
            ,t1.[RestraintInfo] as restraint_info
            ,t1.[TransmissionInfo] as transmission_info
            ,t1.[OtherInfo] as other_info
            ,t1.[ReleaseDate] as vehicle_release_dt
            ,t1.[MotorHomeClass] as motor_home_class
            ,t1.[PassengerHazardExclusion] as passenger_hazard_exclusion_in
            ,t1.bodily_injury_premium_adjustment_method
            ,t1.bodily_injury_premium_adjustment_amount
            ,t1.bodily_injury_premium_adjustment_retention
            ,t1.bodily_injury_premium_adjustment_reason
            ,t1.property_damage_premium_adjustment_method
            ,t1.property_damage_premium_adjustment_amount
            ,t1.property_damage_premium_adjustment_retention
            ,t1.property_damage_premium_adjustment_reason
            ,t1.medical_payments_premium_adjustment_method
            ,t1.medical_payments_premium_adjustment_amount
            ,t1.medical_payments_premium_adjustment_retention
            ,t1.medical_payments_premium_adjustment_reason
            ,t1.uninsured_motorist_premium_adjustment_method
            ,t1.uninsured_motorist_premium_adjustment_amount
            ,t1.uninsured_motorist_premium_adjustment_retention
            ,t1.uninsured_motorist_premium_adjustment_reason
            ,t1.other_than_collision_premium_adjustment_method
            ,t1.other_than_collision_premium_adjustment_amount
            ,t1.other_than_collision_premium_adjustment_retention
            ,t1.other_than_collision_premium_adjustment_reason
            ,t1.collision_premium_adjustment_method
            ,t1.collision_premium_adjustment_amount
            ,t1.collision_premium_adjustment_retention
            ,t1.collision_premium_adjustment_reason
            ,t1.personal_injury_protection_premium_adjustment_method
            ,t1.personal_injury_protection_premium_adjustment_amount
            ,t1.personal_injury_protection_premium_adjustment_retention
            ,t1.personal_injury_protection_premium_adjustment_reason
            ,t1.extended_towing_labor_premium_adjustment_method
            ,t1.extended_towing_labor_premium_adjustment_amount
            ,t1.extended_towing_labor_premium_adjustment_retention
            ,t1.extended_towing_labor_premium_adjustment_reason
            ,t1.[NewlyPurchasedVehicle] as newly_purchased_vehicle_override_in
            ,t1.[NewlyPurchasedVehicleDate] as newly_purchased_vehicle_dt
            ,t1.[NewlyPurchasedVehicleFinal] as newly_purchased_vehicle_final_in
        FROM 
            [edw_temp].[tauto_vehicle_coverage_temp1] AS t1
        left join [edw_stage].[AccountTransactionVersionObject] AS atvo ON atvo.id = t1.GaragingLocationId
        left join[edw_core].[tauto_garage_location] AS gar 
					ON gar.policy_no = t1.policy_no and gar.effective_dt = t1.effective_dt and gar.transaction_seq_no = t1.transaction_seq_no and gar.garage_location_no = atvo.[Index]
        left join ( select rank() over (partition by policy_no, effective_dt, transaction_seq_no order by policy_no, effective_dt, transaction_seq_no,garage_location_no) rnk, *
				from [edw_core].[tauto_garage_location] 
		) gar1 on gar1.rnk = 1 and  gar1.policy_no = t1.policy_no and gar1.effective_dt = t1.effective_dt and t1.transaction_seq_no = gar1.transaction_seq_no
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_vehicle_coverage_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp1];
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp2];
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_temp3];

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
