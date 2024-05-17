SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO   
-- ================================================================================================================================================
-- Description: This stored procedure inserts and updates info related to quote auto policy coverage - wip
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 05/06/24		Alberto Almario					1. Created the proc
-- 05/08/24		Architha Gudimalla				2. Updated @last_source_extract_ts
-- 05/14/24		Architha Gudimalla				3. Corrected errors
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_policy_coverage_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_policy_coverage_wip_temp1];

		SELECT 
			CreatedDate, UpdatedDate, quote_no, effective_dt, expiration_dt, 0 as transaction_seq_no, quote_history_sk,
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
            [NCViolations], [NCAccidents], [NumberofMotorcycles], [NumberofOtherMiscVehicles], [MultiBikeDiscount], [MulticarDiscount], [IncludeChangeInTermsSummary], [YearCleanDiscountApplied], [RaterPIPDiscount],
			source_system_sk, [NCRBPPACOLLTotal],[NCRBPPAOTCTotal], [TransportationExpense], [TransportationExpenseDailyLimit], [TransportationExpenseCoPay]
		
        INTO [edw_temp].[tquote_auto_policy_coverage_wip_temp1]
		
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, 
                    acc.ExpirationDate as expiration_dt, --acc.Number as transaction_seq_no,
                    qh.quote_history_sk,
                    accof.[Field], accof.[Value],
                    CASE 
                        WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (
                        SELECT *
                        FROM [edw_stage].[Account] AS a
                        WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                    ) acc
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                LEFT JOIN [edw_core].[tquote_history] AS qh 
                    ON qh.quote_no = acc.PolicyNumber
                    AND qh.effective_dt = acc.EffectiveDate
                    AND qh.transaction_seq_no = 0
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Coverages','Additional Coverages','Coverage Limitations','Policy Discount','NCRB Premium','Discounts')
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
                    [NCViolations], [NCAccidents], [NumberofMotorcycles], [NumberofOtherMiscVehicles], [MultiBikeDiscount], [MulticarDiscount], [IncludeChangeInTermsSummary], [YearCleanDiscountApplied], 
                    [RaterPIPDiscount], [NCRBPPACOLLTotal],[NCRBPPAOTCTotal], [TransportationExpense], [TransportationExpenseDailyLimit], [TransportationExpenseCoPay]
                )
			) pivottable

        declare @edw_field_nm VARCHAR(255)
        declare @metal_field_nm VARCHAR(255)
        declare @sql nvarchar(max)

        DECLARE c1_rec CURSOR
        FOR 
        select 'AdditionalPIP'			as edw_field_nm, 'AdditionalPIP'		metal_field_nm union all
        select 'BasicPIP'				as edw_field_nm, 'BasicPIP'				metal_field_nm union all
        select 'BILimit'				as edw_field_nm, 'BILimit'				metal_field_nm union all
        select 'DeductibleAppliesTo'	as edw_field_nm, 'DeductibleAppliesTo'	metal_field_nm union all
        select 'UIMLimit'				as edw_field_nm, 'UIMLimit'				metal_field_nm union all
        select 'UMBIPolicyLimit'		as edw_field_nm, 'UMBIPolicyLimit'		metal_field_nm union all
        select 'UMLimit'				as edw_field_nm, 'UMLimit'				metal_field_nm union all 
        select 'WorkLossExclusion'		as edw_field_nm, 'WorkLossExclusion'	metal_field_nm

        open c1_rec; 
            FETCH NEXT FROM c1_rec INTO @edw_field_nm, @metal_field_nm; 
            WHILE @@FETCH_STATUS = 0
                BEGIN 

                    set @sql =	'
                            update		avc 
                            set			avc.' + @edw_field_nm + ' = replace( pfvd.ValueDisplay,''$'','''') 
                            from		[edw_temp].[tquote_auto_policy_coverage_wip_temp1] avc
                            inner join	edw_core.tquote pol on  avc.quote_no = pol.quote_no and avc.effective_dt = pol.effective_dt
                            inner join	[edw_stage].[ProductObjectFieldValueDisplay] pfvd 
                                                    on pfvd.StateCode = pol.risk_state_cd and pfvd.ObjectType = ''Automobile'' and pfvd.field = ''' + @metal_field_nm + ''' and avc.' + @edw_field_nm + ' = pfvd.Value
                            where		avc.' + @edw_field_nm + ' is not null and replace( pfvd.ValueDisplay,''$'','''') is not null
                            '
                    --print @sql

                    EXECUTE sp_executesql @sql
                    
                    FETCH NEXT FROM c1_rec INTO @edw_field_nm, @metal_field_nm;
                END; 
            CLOSE c1_rec;
            DEALLOCATE c1_rec;

		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_policy_coverage] AS target
        USING [edw_temp].[tquote_auto_policy_coverage_wip_temp1] AS source
            ON target.quote_no = source.quote_no
            AND target.effective_dt = source.effective_dt
            AND target.transaction_seq_no = source.transaction_seq_no
        WHEN MATCHED THEN
            UPDATE SET
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.limit_type = source.[LimitType],
                target.combined_single_limit_amt = source.[CombinedSingleLimit],
                target.bodily_injury_limit_amt = source.[BILimit],
                target.property_damage_limit_amt = source.[PDLimit],
                target.limited_property_damage = source.[LimitedPD],
                target.uninsured_underinsured_motorist_type = source.[UMType],
                target.uninsured_motorist_limit_amt = source.[UMLimit],
                target.underinsured_motorist_limit_amt = source.[UIMLimit],
                target.combined_uninsured_motorist_limit_amt = source.[CombinedUMLimit],
                target.combined_underinsured_motorist_limit_amt = source.[CombinedUIMLimit],
                target.um_bi_policy_limit_amt = source.[UMBIPolicyLimit],
                target.um_pd_policy_limit_amt = source.[UMPDPolicyLimit],
                target.combined_um_bi_policy_limit_amt = source.[CombinedUMBIPolicyLimit],
                target.combined_um_pd_policy_limit_amt = source.[CombinedUMPDPolicyLimit],
                target.pip_limit_amt = source.[PIPLimit],
                target.pip_deductible = source.[PIPDeductible],
                target.medical_payment_limit_amt = source.[MedicalPaymentLimit],
                target.property_protection = source.[PropertyProtection],
                target.stacked_or_nonstacked = source.[Stacking],
                target.uninsured_motorist_added_reduced = source.[UMAddedReduced],
                target.uninsured_motorist_deductible = source.[UMDeductible],
                target.economic_loss_uninsured_motorist_in = source.[EconomicLossUM],
                target.automobile_death_indemnity_and_disability_income = source.[AutomobileDeathIndemnityAndDisabilityIncome],
                target.cede_to_ncrf = source.[CedetoNCRF],
                target.basic_pip = source.[BasicPIP],
                target.basic_or_extended_pip = source.[BasicOrExtendedPIP],
                target.additional_pip = source.[AdditionalPIP],
                target.pip_medical_options = source.[PIPMedicalOptions],
                target.extended_medical_limit_amt = source.[ExtendedMedical],
                target.tort = source.[Tort],
                target.deletion_of_benefits_in = source.[DeletionOfBenefits],
                target.basic_or_added_first_party_benefit = source.[BasicOrAddedFirstPartyBenefit],
                target.individual_or_combination_fpb = source.[IndividualOrCombinationFPB],
                target.added_first_party_limit_amt = source.[AddedFirstPartyLimits],
                target.accidental_death_benefit_limit_amt = source.[AccidentalDeathBenefit],
                target.work_loss_benefit_limit_amt = source.[WorkLossBenefit],
                target.funeral_expense_benefit_limit_amt = source.[FuneralExpenseBenefit],
                target.combination_fpb_limit_amt = source.[CombinationFPB],
                target.extraordinary_medical_benefits_limit_amt = source.[ExtraordinaryMedicalBenefits],
                target.coordination_of_medical_benefits_in = source.[CoordinationofMedicalBenefits],
                target.work_loss_rejection_in = source.[WorkLossRejection],
                target.coordination_of_work_loss_benefits_in = source.[CoordinationofWorkLossBenefits],
                target.excess_attendant_care_in = source.[ExcessAttendantCare],
                target.health_insurance_primary_in = source.[HealthPrimary],
                target.deductible_applies_to = source.[DeductibleAppliesTo],
                target.work_loss_exclusion = source.[WorkLossExclusion],
                target.income_loss_benefit_in = source.[IncomeLossBenefit],
                target.named_non_owner_in = source.[NamedNonOwner],
                target.extended_non_owned_in = source.[ExtendedNonOwned],
                target.primary_insurance_elsewhere_in = source.[PrimaryInsuranceElsewhere],
                target.extend_to = source.[Extendto],
                target.named_individual = source.[NamedIndividual],
                target.auto_complete_coverage_in = source.[AutoCompleteCoverage],
                target.emergency_movement_coverage_in = source.[EmergencyMovementCoverage],
                target.physical_damage_deductible_adjustment = source.[PhysicalDamageDeductibleAdjustment],
                target.multiple_policy_deductible_enhancement_endorsement_in = source.[MultiplePolicyDeductibleEnhancementEndorsement],
                target.transportation_and_temporary_emergency_living_expense_in = source.[TransportationandTemporaryEmergencyLivingExpense],
                target.stated_value_enhancement_endorsement_in = source.[StatedValueEnhancementEndorsement],
                target.original_equipment_manufacturer_enhancement_endorsement_in = source.[OriginalEquipmentManufacturerEnhancementEndorsement],
                target.full_glass_coverage_enhancement_endorsement_in = source.[FullGlassCoverageEnhancementEndorsement],
                target.waiver_of_collision_enhancement_endorsement_in = source.[WaiverofCollisionEnhancementEndorsement],
                target.petInjury_enhancement_endorsement_in = source.[PetInjuryEnhancementEndorsement],
                target.auto_lock_coverage_enhancement_endorsement_in = source.[AutoLockCoverageEnhancementEndorsement],
                target.spare_parts_enhancement_endorsement_in = source.[SparePartsEnhancementEndorsement],
                target.coverage_for_accidental_deploy_airbag_enhancement_endorsement_in = source.[CoverageforAccidentalDeployAirbagEnhancementEndorsement],
                target.one_year_policy_in = source.[IsthisOneYearPolicy],
                target.tier = source.[Tier],
                target.total_vehicles_on_policy_ct = source.[NumberofTotalVehiclesonPolicy],
                target.total_ppas_ct = source.[TotalNumberofPPAs],
                target.total_owned_ppas_ct = source.[TotalOwnedPPAs],
                target.ppa_with_physical_damage_ct = source.[NumberofPPAwithPhysDam],
                target.collector_cars_ct = source.[NumberofCollectorCars],
                target.total_insured_locations_ct = source.[TotalInsuredLocations],
                target.ho_claims_ct = source.[HOClaims],
                target.drivers_on_policy_ct = source.[NumberofDriversonPolicy],
                target.youths_on_policy_ct = source.[NumberofYouthsonPolicy],
                target.years_clean_discount = source.[YearsCleanDiscount],
                target.youthful_on_policy_in = source.[YouthfulonPolicy],
                target.prior_carrier_naf_points = source.[PriorCarrierNAFPoints],
                target.prior_carrier_minor_accidents_ct = source.[PriorCarrierMinorAccidents],
                target.prior_carrier_minor_accidents_points = source.[PriorCarrierMinorAccidentsPoints],
                target.sdip_points = source.[SDIPPoints],
                target.comp_claims_ct = source.[COMPClaims],
                target.nc_violations_ct = source.[NCViolations],
                target.nc_accidents_ct = source.[NCAccidents],
                target.motorcycles_ct = source.[NumberofMotorcycles],
                target.other_misc_vehicles_ct = source.[NumberofOtherMiscVehicles],
                target.multi_bike_discount_in = source.[MultiBikeDiscount],
                target.multi_car_discount_in = source.[MulticarDiscount],
                target.source_system_sk = source.source_system_sk,
                target.update_ts = GETDATE(),
                target.etl_audit_sk = @etl_audit_sk,
                target.change_in_terms_summary_in = source.[IncludeChangeInTermsSummary],
                target.year_clean_discount_applied = source.[YearCleanDiscountApplied],
                target.rater_pip_discount = source.[RaterPIPDiscount],
                target.collision_ncrb_premium_amt = source.[NCRBPPACOLLTotal],
                target.otc_ncrb_premium_amt = source.[NCRBPPAOTCTotal],
                target.transportation_expense_amt = source.[TransportationExpense],
                target.transportation_expense_daily_limit_amt = source.[TransportationExpenseDailyLimit],
                target.transportation_expense_copay_amt = source.[TransportationExpenseCoPay]
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no,
                effective_dt,
                expiration_dt,
                transaction_seq_no,
                quote_history_sk,
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
                etl_audit_sk,
                change_in_terms_summary_in,
                year_clean_discount_applied,
                rater_pip_discount,
                collision_ncrb_premium_amt,
                otc_ncrb_premium_amt,
                transportation_expense_amt,
                transportation_expense_daily_limit_amt,
                transportation_expense_copay_amt
            )
            VALUES (
                source.quote_no,
                source.effective_dt,
                source.expiration_dt,
                source.transaction_seq_no,
                source.quote_history_sk,
                source.[LimitType],
                source.[CombinedSingleLimit],
                source.[BILimit],
                source.[PDLimit],
                source.[LimitedPD],
                source.[UMType],
                source.[UMLimit],
                source.[UIMLimit],
                source.[CombinedUMLimit],
                source.[CombinedUIMLimit],
                source.[UMBIPolicyLimit],
                source.[UMPDPolicyLimit],
                source.[CombinedUMBIPolicyLimit],
                source.[CombinedUMPDPolicyLimit],
                source.[PIPLimit],
                source.[PIPDeductible],
                source.[MedicalPaymentLimit],
                source.[PropertyProtection],
                source.[Stacking],
                source.[UMAddedReduced],
                source.[UMDeductible],
                source.[EconomicLossUM],
                source.[AutomobileDeathIndemnityAndDisabilityIncome],
                source.[CedetoNCRF],
                source.[BasicPIP],
                source.[BasicOrExtendedPIP],
                source.[AdditionalPIP],
                source.[PIPMedicalOptions],
                source.[ExtendedMedical],
                source.[Tort],
                source.[DeletionOfBenefits],
                source.[BasicOrAddedFirstPartyBenefit],
                source.[IndividualOrCombinationFPB],
                source.[AddedFirstPartyLimits],
                source.[AccidentalDeathBenefit],
                source.[WorkLossBenefit],
                source.[FuneralExpenseBenefit],
                source.[CombinationFPB],
                source.[ExtraordinaryMedicalBenefits],
                source.[CoordinationofMedicalBenefits],
                source.[WorkLossRejection],
                source.[CoordinationofWorkLossBenefits],
                source.[ExcessAttendantCare],
                source.[HealthPrimary],
                source.[DeductibleAppliesTo],
                source.[WorkLossExclusion],
                source.[IncomeLossBenefit],
                source.[NamedNonOwner],
                source.[ExtendedNonOwned],
                source.[PrimaryInsuranceElsewhere],
                source.[Extendto],
                source.[NamedIndividual],
                source.[AutoCompleteCoverage],
                source.[EmergencyMovementCoverage],
                source.[PhysicalDamageDeductibleAdjustment],
                source.[MultiplePolicyDeductibleEnhancementEndorsement],
                source.[TransportationandTemporaryEmergencyLivingExpense],
                source.[StatedValueEnhancementEndorsement],
                source.[OriginalEquipmentManufacturerEnhancementEndorsement],
                source.[FullGlassCoverageEnhancementEndorsement],
                source.[WaiverofCollisionEnhancementEndorsement],
                source.[PetInjuryEnhancementEndorsement],
                source.[AutoLockCoverageEnhancementEndorsement],
                source.[SparePartsEnhancementEndorsement],
                source.[CoverageforAccidentalDeployAirbagEnhancementEndorsement],
                source.[IsthisOneYearPolicy],
                source.[Tier],
                source.[NumberofTotalVehiclesonPolicy],
                source.[TotalNumberofPPAs],
                source.[TotalOwnedPPAs],
                source.[NumberofPPAwithPhysDam],
                source.[NumberofCollectorCars],
                source.[TotalInsuredLocations],
                source.[HOClaims],
                source.[NumberofDriversonPolicy],
                source.[NumberofYouthsonPolicy],
                source.[YearsCleanDiscount],
                source.[YouthfulonPolicy],
                source.[PriorCarrierNAFPoints],
                source.[PriorCarrierMinorAccidents],
                source.[PriorCarrierMinorAccidentsPoints],
                source.[SDIPPoints],
                source.[COMPClaims],
                source.[NCViolations],
                source.[NCAccidents],
                source.[NumberofMotorcycles],
                source.[NumberofOtherMiscVehicles],
                source.[MultiBikeDiscount],
                source.[MulticarDiscount],
                source.source_system_sk,
                GETDATE(),
                GETDATE(),
                @etl_audit_sk,
                source.[IncludeChangeInTermsSummary],
                source.[YearCleanDiscountApplied],
                source.[RaterPIPDiscount],
                source.[NCRBPPACOLLTotal],
                source.[NCRBPPAOTCTotal],
                source.[TransportationExpense],
                source.[TransportationExpenseDailyLimit],
                source.[TransportationExpenseCoPay]
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(CreatedDate,UpdatedDate)) FROM edw_temp.[tquote_auto_policy_coverage_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_policy_coverage_wip_temp1];

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
