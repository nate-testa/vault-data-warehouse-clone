SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-13
-- Description: This stored procedure insert and update info related to tauto_policy_coverage.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_policy_coverage]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_policy_coverage_temp1];

		SELECT 
			IssuedDate, policy_no, effective_dt, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, policy_history_sk,
            [LimitType], [CombinedSingleLimit], [BILimit], [PDLimit], [LimitedPD], [UMType], [UMLimit], [UIMLimit], [CombinedUMLimit], [CombinedUIMLimit], [UMBIPolicyLimit], [UMPDPolicyLimit], 
            [CombinedUMBIPolicyLimit], [CombinedUMPDPolicyLimit], [PIPLimit], [PIPDeductible], [MedicalPaymentLimit], [PropertyProtection], [Stacking], [UMAddedReduced], [UMDeductible], [EconomicLossUM], 
            [AutomobileDeathIndemnityAndDisabilityIncome], [CedetoNCRF], [BasicPIP], [BasicOrExtendedPIP], [AdditionalPIP], [PIPMedicalOptions], [ExtendedMedical], [Tort], [DeletionOfBenefits], 
            [BasicOrAddedFirstPartyBenefit], [IndividualOrCombinationFPB], [AddedFirstPartyLimits], [AccidentalDeathBenefit], [WorkLossBenefit], [FuneralExpenseBenefit], [CombinationFPB], 
            [ExtraordinaryMedicalBenefits], [CoordinationofMedicalBenefits], [WorkLossRejection], [CoordinationofWorkLossBenefits], [ExcessAttendantCare], [HealthPrimary], [DeductibleAppliesTo], 
            [WorkLossExclusion], [IncomeLossBenefit], [NamedNonOwner], [ExtendedNonOwned], [PrimaryInsuranceElsewhere], [Extendto], [NamedIndividual], [AutoCompleteCoverage], [EmergencyMovementCoverage], 
            [PhysicalDamageDeductibleAdjustment], [MultiplePolicyDeductibleEnhancementEndorsement], [TransportationandTemporaryEmergencyLivingExpense], [StatedValueEnhancementEndorsement], 
            [OriginalEquipmentManufacturerEnhancementEndorsement], [FullGlassCoverageEnhancementEndorsement], [WaiverofCollisionEnhancementEndorsement], [PetInjuryEnhancementEndorsement], 
            [AutoLockCoverageEnhancementEndorsement], [SparePartsEnhancementEndorsement], [CoverageforAccidentalDeployAirbagEnhancementEndorsement], [IsthisOneYearPolicy], [Tier], 
            [NumberofTotalVehiclesonPolicy], [TotalNumberofPPAs], [TotalOwnedPPAs], [NumberofPPAwithPhysDam], [NumberofCollectorCars], [TotalInsuredLocations], [HOClaims], [NumberofDriversonPolicy], 
            [NumberofYouthsonPolicy], [YearsCleanDiscount], [YouthfulonPolicy], [PriorCarrierNAFPoints], [PriorCarrierMinorAccidents], [PriorCarrierMinorAccidentsPoints], [SDIPPoints], [COMPClaims], 
            [NCViolations], [NCAccidents], [NumberofMotorcycles], [NumberofOtherMiscVehicles], [MultiBikeDiscount], [MulticarDiscount],
			source_system_sk
		
        INTO [edw_temp].[tauto_policy_coverage_temp1]
		
        FROM
			(
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                    ph.policy_history_sk,
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (SELECT
                        *
                        ,ROW_NUMBER() OVER (PARTITION BY PolicyNumber, EffectiveDate ORDER BY policychangenumber DESC) AS AccountTransaction_Rank
                    FROM [edw_stage].[AccountTransaction]
                    WHERE [State] = 'ISSUED'
                        AND IssuedDate > @last_source_extract_ts
                    ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                    ON ph.policy_no = acct.PolicyNumber
                    AND ph.effective_dt = acct.EffectiveDate
                    AND ph.transaction_seq_no = acct.policychangenumber
                WHERE
                    acct.AccountTransaction_Rank = 1
                    AND p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Coverages','Additional Coverages')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [LimitType], [CombinedSingleLimit], [BILimit], [PDLimit], [LimitedPD], [UMType], [UMLimit], [UIMLimit], [CombinedUMLimit], [CombinedUIMLimit], [UMBIPolicyLimit], [UMPDPolicyLimit], 
                    [CombinedUMBIPolicyLimit], [CombinedUMPDPolicyLimit], [PIPLimit], [PIPDeductible], [MedicalPaymentLimit], [PropertyProtection], [Stacking], [UMAddedReduced], [UMDeductible], [EconomicLossUM], 
                    [AutomobileDeathIndemnityAndDisabilityIncome], [CedetoNCRF], [BasicPIP], [BasicOrExtendedPIP], [AdditionalPIP], [PIPMedicalOptions], [ExtendedMedical], [Tort], [DeletionOfBenefits], 
                    [BasicOrAddedFirstPartyBenefit], [IndividualOrCombinationFPB], [AddedFirstPartyLimits], [AccidentalDeathBenefit], [WorkLossBenefit], [FuneralExpenseBenefit], [CombinationFPB], 
                    [ExtraordinaryMedicalBenefits], [CoordinationofMedicalBenefits], [WorkLossRejection], [CoordinationofWorkLossBenefits], [ExcessAttendantCare], [HealthPrimary], [DeductibleAppliesTo], 
                    [WorkLossExclusion], [IncomeLossBenefit], [NamedNonOwner], [ExtendedNonOwned], [PrimaryInsuranceElsewhere], [Extendto], [NamedIndividual], [AutoCompleteCoverage], [EmergencyMovementCoverage], 
                    [PhysicalDamageDeductibleAdjustment], [MultiplePolicyDeductibleEnhancementEndorsement], [TransportationandTemporaryEmergencyLivingExpense], [StatedValueEnhancementEndorsement], 
                    [OriginalEquipmentManufacturerEnhancementEndorsement], [FullGlassCoverageEnhancementEndorsement], [WaiverofCollisionEnhancementEndorsement], [PetInjuryEnhancementEndorsement], 
                    [AutoLockCoverageEnhancementEndorsement], [SparePartsEnhancementEndorsement], [CoverageforAccidentalDeployAirbagEnhancementEndorsement], [IsthisOneYearPolicy], [Tier], 
                    [NumberofTotalVehiclesonPolicy], [TotalNumberofPPAs], [TotalOwnedPPAs], [NumberofPPAwithPhysDam], [NumberofCollectorCars], [TotalInsuredLocations], [HOClaims], [NumberofDriversonPolicy], 
                    [NumberofYouthsonPolicy], [YearsCleanDiscount], [YouthfulonPolicy], [PriorCarrierNAFPoints], [PriorCarrierMinorAccidents], [PriorCarrierMinorAccidentsPoints], [SDIPPoints], [COMPClaims], 
                    [NCViolations], [NCAccidents], [NumberofMotorcycles], [NumberofOtherMiscVehicles], [MultiBikeDiscount], [MulticarDiscount]
                )
			) pivottable

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_policy_coverage]
        (
            policy_no,
            effective_dt,
            transaction_effective_dt,
            expiration_dt,
            transaction_dt,
            transaction_seq_no,
            policy_history_sk,
            limit_type,
            combined_single_limit_amt,
            bodily_injury_limit_amt,
            property_damage_limit_amt,
            limited_property_damage,
            uninsured_underinsured_motorist_type,
            uninsured_motorist_limit_amt,
            underinsured_motorist_limit_amt,
            combined_uninsured_motorist_limit_amt,
            combined_underinsured_motorist_limit_amt,
            um_bi_policy_limit_amt,
            um_pd_policy_limit_amt,
            combined_um_bi_policy_limit_amt,
            combined_um_pd_policy_limit_amt,
            pip_limit_amt,
            pip_deductible,
            medical_payment_limit_amt,
            property_protection,
            stacked_or_nonstacked,
            uninsured_motorist_added_reduced,
            uninsured_motorist_deductible,
            economic_loss_uninsured_motorist_in,
            automobile_death_indemnity_and_disability_income,
            cede_to_ncrf,
            basic_pip,
            basic_or_extended_pip,
            additional_pip,
            pip_medical_options,
            extended_medical_limit_amt,
            tort,
            deletion_of_benefits_in,
            basic_or_added_first_party_benefit,
            individual_or_combination_fpb,
            added_first_party_limit_amt,
            accidental_death_benefit_limit_amt,
            work_loss_benefit_limit_amt,
            funeral_expense_benefit_limit_amt,
            combination_fpb_limit_amt,
            extraordinary_medical_benefits_limit_amt,
            coordination_of_medical_benefits_in,
            work_loss_rejection_in,
            coordination_of_work_loss_benefits_in,
            excess_attendant_care_in,
            health_insurance_primary_in,
            deductible_applies_to,
            work_loss_exclusion,
            income_loss_benefit_in,
            named_non_owner_in,
            extended_non_owned_in,
            primary_insurance_elsewhere_in,
            extend_to,
            named_individual,
            auto_complete_coverage_in,
            emergency_movement_coverage_in,
            physical_damage_deductible_adjustment,
            multiple_policy_deductible_enhancement_endorsement_in,
            transportation_and_temporary_emergency_living_expense_in,
            stated_value_enhancement_endorsement_in,
            original_equipment_manufacturer_enhancement_endorsement_in,
            full_glass_coverage_enhancement_endorsement_in,
            waiver_of_collision_enhancement_endorsement_in,
            petInjury_enhancement_endorsement_in,
            auto_lock_coverage_enhancement_endorsement_in,
            spare_parts_enhancement_endorsement_in,
            coverage_for_accidental_deploy_airbag_enhancement_endorsement_in,
            one_year_policy_in,
            tier,
            total_vehicles_on_policy_ct,
            total_ppas_ct,
            total_owned_ppas_ct,
            ppa_with_physical_damage_ct,
            collector_cars_ct,
            total_insured_locations_ct,
            ho_claims_ct,
            drivers_on_policy_ct,
            youths_on_policy_ct,
            years_clean_discount,
            youthful_on_policy_in,
            prior_carrier_naf_points,
            prior_carrier_minor_accidents_ct,
            prior_carrier_minor_accidents_points,
            sdip_points,
            comp_claims_ct,
            nc_violations_ct,
            nc_accidents_ct,
            motorcycles_ct,
            other_misc_vehicles_ct,
            multi_bike_discount_in,
            multi_car_discount_in,
            source_system_sk,
            create_ts,
            update_ts,
            etl_audit_sk
		)
        SELECT 
            t1.policy_no,
            t1.effective_dt,
            t1.transaction_effective_dt,
            t1.expiration_dt,
            t1.transaction_dt,
            t1.transaction_seq_no,
            t1.policy_history_sk,
            t1.[LimitType] as limit_type,
            t1.[CombinedSingleLimit] as combined_single_limit_amt,
            t1.[BILimit] as bodily_injury_limit_amt,
            t1.[PDLimit] as property_damage_limit_amt,
            t1.[LimitedPD] as limited_property_damage,
            t1.[UMType] as uninsured_underinsured_motorist_type,
            t1.[UMLimit] as uninsured_motorist_limit_amt,
            t1.[UIMLimit] as underinsured_motorist_limit_amt,
            t1.[CombinedUMLimit] as combined_uninsured_motorist_limit_amt,
            t1.[CombinedUIMLimit] as combined_underinsured_motorist_limit_amt,
            t1.[UMBIPolicyLimit] as um_bi_policy_limit_amt,
            t1.[UMPDPolicyLimit] as um_pd_policy_limit_amt,
            t1.[CombinedUMBIPolicyLimit] as combined_um_bi_policy_limit_amt,
            t1.[CombinedUMPDPolicyLimit] as combined_um_pd_policy_limit_amt,
            t1.[PIPLimit] as pip_limit_amt,
            t1.[PIPDeductible] as pip_deductible,
            t1.[MedicalPaymentLimit] as medical_payment_limit_amt,
            t1.[PropertyProtection] as property_protection,
            t1.[Stacking] as stacked_or_nonstacked,
            t1.[UMAddedReduced] as uninsured_motorist_added_reduced,
            t1.[UMDeductible] as uninsured_motorist_deductible,
            t1.[EconomicLossUM] as economic_loss_uninsured_motorist_in,
            t1.[AutomobileDeathIndemnityAndDisabilityIncome] as automobile_death_indemnity_and_disability_income,
            t1.[CedetoNCRF] as cede_to_ncrf,
            t1.[BasicPIP] as basic_pip,
            t1.[BasicOrExtendedPIP] as basic_or_extended_pip,
            t1.[AdditionalPIP] as additional_pip,
            t1.[PIPMedicalOptions] as pip_medical_options,
            t1.[ExtendedMedical] as extended_medical_limit_amt,
            t1.[Tort] as tort,
            t1.[DeletionOfBenefits] as deletion_of_benefits_in,
            t1.[BasicOrAddedFirstPartyBenefit] as basic_or_added_first_party_benefit,
            t1.[IndividualOrCombinationFPB] as individual_or_combination_fpb,
            t1.[AddedFirstPartyLimits] as added_first_party_limit_amt,
            t1.[AccidentalDeathBenefit] as accidental_death_benefit_limit_amt,
            t1.[WorkLossBenefit] as work_loss_benefit_limit_amt,
            t1.[FuneralExpenseBenefit] as funeral_expense_benefit_limit_amt,
            t1.[CombinationFPB] as combination_fpb_limit_amt,
            t1.[ExtraordinaryMedicalBenefits] as extraordinary_medical_benefits_limit_amt,
            t1.[CoordinationofMedicalBenefits] as coordination_of_medical_benefits_in,
            t1.[WorkLossRejection] as work_loss_rejection_in,
            t1.[CoordinationofWorkLossBenefits] as coordination_of_work_loss_benefits_in,
            t1.[ExcessAttendantCare] as excess_attendant_care_in,
            t1.[HealthPrimary] as health_insurance_primary_in,
            t1.[DeductibleAppliesTo] as deductible_applies_to,
            t1.[WorkLossExclusion] as work_loss_exclusion,
            t1.[IncomeLossBenefit] as income_loss_benefit_in,
            t1.[NamedNonOwner] as named_non_owner_in,
            t1.[ExtendedNonOwned] as extended_non_owned_in,
            t1.[PrimaryInsuranceElsewhere] as primary_insurance_elsewhere_in,
            t1.[Extendto] as extend_to,
            t1.[NamedIndividual] as named_individual,
            t1.[AutoCompleteCoverage] as auto_complete_coverage_in,
            t1.[EmergencyMovementCoverage] as emergency_movement_coverage_in,
            t1.[PhysicalDamageDeductibleAdjustment] as physical_damage_deductible_adjustment,
            t1.[MultiplePolicyDeductibleEnhancementEndorsement] as multiple_policy_deductible_enhancement_endorsement_in,
            t1.[TransportationandTemporaryEmergencyLivingExpense] as transportation_and_temporary_emergency_living_expense_in,
            t1.[StatedValueEnhancementEndorsement] as stated_value_enhancement_endorsement_in,
            t1.[OriginalEquipmentManufacturerEnhancementEndorsement] as original_equipment_manufacturer_enhancement_endorsement_in,
            t1.[FullGlassCoverageEnhancementEndorsement] as full_glass_coverage_enhancement_endorsement_in,
            t1.[WaiverofCollisionEnhancementEndorsement] as waiver_of_collision_enhancement_endorsement_in,
            t1.[PetInjuryEnhancementEndorsement] as petInjury_enhancement_endorsement_in,
            t1.[AutoLockCoverageEnhancementEndorsement] as auto_lock_coverage_enhancement_endorsement_in,
            t1.[SparePartsEnhancementEndorsement] as spare_parts_enhancement_endorsement_in,
            t1.[CoverageforAccidentalDeployAirbagEnhancementEndorsement] as coverage_for_accidental_deploy_airbag_enhancement_endorsement_in,
            t1.[IsthisOneYearPolicy] as one_year_policy_in,
            t1.[Tier] as tier,
            t1.[NumberofTotalVehiclesonPolicy] as total_vehicles_on_policy_ct,
            t1.[TotalNumberofPPAs] as total_ppas_ct,
            t1.[TotalOwnedPPAs] as total_owned_ppas_ct,
            t1.[NumberofPPAwithPhysDam] as ppa_with_physical_damage_ct,
            t1.[NumberofCollectorCars] as collector_cars_ct,
            t1.[TotalInsuredLocations] as total_insured_locations_ct,
            t1.[HOClaims] as ho_claims_ct,
            t1.[NumberofDriversonPolicy] as drivers_on_policy_ct,
            t1.[NumberofYouthsonPolicy] as youths_on_policy_ct,
            t1.[YearsCleanDiscount] as years_clean_discount,
            t1.[YouthfulonPolicy] as youthful_on_policy_in,
            t1.[PriorCarrierNAFPoints] as prior_carrier_naf_points,
            t1.[PriorCarrierMinorAccidents] as prior_carrier_minor_accidents_ct,
            t1.[PriorCarrierMinorAccidentsPoints] as prior_carrier_minor_accidents_points,
            t1.[SDIPPoints] as sdip_points,
            t1.[COMPClaims] as comp_claims_ct,
            t1.[NCViolations] as nc_violations_ct,
            t1.[NCAccidents] as nc_accidents_ct,
            t1.[NumberofMotorcycles] as motorcycles_ct,
            t1.[NumberofOtherMiscVehicles] as other_misc_vehicles_ct,
            t1.[MultiBikeDiscount] as multi_bike_discount_in,
            t1.[MulticarDiscount] as multi_car_discount_in,
            t1.source_system_sk,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        FROM 
            [edw_temp].[tauto_policy_coverage_temp1] AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_policy_coverage_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_policy_coverage_temp1];

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
