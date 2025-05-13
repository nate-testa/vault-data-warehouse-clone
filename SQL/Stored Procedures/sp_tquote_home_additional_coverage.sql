SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert homeowners quote additional coverage data
------------------------------------------------------------------------------------------------------------------------------
-- Change date				|Author										|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 10/23/23					Yunus Mohammed					1. Created this procedure 
-- 11/11/23					Sandeep Gundreddy		    	2. Modified join to tquote_history
-- 11/14/23					Sandeep Gundreddy		    	3. Modified tqupte_home_location_sk join
-- 11/17/23					Yunus Mohammed					4. Added new columns
-- 01/18/24					Alberto Almario						  5. Added new column extended_liability_location_ct
-- 01/25/24					Alberto Almario						  6. Added new columns roof_exclusion_with_ensuing_loss_in, 	
--																								 roof_coverage_endorsement_wh_in, 
--																		 						roof_coverage_endorsement_ap_in,
--																		 						roof_coverage_endorsement_rv_in
-- 09/07/24				Hernando Gonzalez					 7. Added new columns trampoline_liability_exclusion_in, fine_arts_exclusion_in, screen_enclosure_coverage_in, screen_enclosure_limit_amt, matching_undamaged_property_in, matching_undamaged_property_limit_amt, roof_covering_coverage_limitation_all_peril_loss_settlement_endorsement_in, all_peril_roof_covering_coverage_limitation_loss_settlement_endorsement_in
-- 08/01/24             Tuba Mohsin                 				8. added contents_extended_replacement_cost_limit_amt
-- 08/30/24				Yunus Mohammed						9. Added new columns
-- 10/02/24				Yunus Mohammed						10. Added new column fortified_roof_upgrade_endorsement_in
-- 10/30/24				Hernando Gonzalez					 11. AD-7502 | Added new columns fortified_roof_program_discount_amt, non_program_discount_amt
-- 12/02/24				Yunus Mohammed						12. AD-7834 Added new fields
-- 12/18/24				Hernando Gonzalez					 13. AD-7963 | Added Risk_Score_Fire
-- 01/22/25				Alberto Almario							  14. Added new columns theft_or_loss_general_conditions_endorsement_in, animal_related_liability_endorsement_in
-- 04/01/25		   		Yunus Mohammed						15 Ad-9035 Added automatic_seismic_shutoff_valve_in
--05/12/25				Yunus Mohammed				        16 AD-9481 Added all_peril_roof_covering_coverage_CW_in
-- =========================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_home_additional_coverage]

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
		-- Get column names to pivot
		DECLARE @ColumnsToPivot NVARCHAR(MAX)=''

		SELECT
				@ColumnsToPivot+=QUOTENAME(Field) + ','
		FROM
		(
			SELECT DISTINCT
			pd.[Name],pdo.ObjectType,pdof.Field,pdof.[Group]
			FROM
			edw_stage.Product pd
			INNER JOIN edw_stage.[ProductObject] pdo on pd.Id=pdo.ProductId
			INNER JOIN edw_stage.[ProductObjectField] pdof on pdo.Id=pdof.ProductObjectId
			WHERE
			pd.[Name]='Homeowners'
			AND pdo.ObjectType IN ('Homeowner')
		) AS temp

		-- remove last comma
		SET @ColumnsToPivot = LEFT(@ColumnsToPivot, LEN(@ColumnsToPivot) - 1);
	
		declare @sql nvarchar(max)
		drop table if exists edw_temp.tquote_home_additional_coverage_temp1
		SET @sql ='select quote_no,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,
		CreatedDate,quote_history_sk,quote_home_location_sk,quote_home_coverage_sk,source_system_sk,
		'+ @ColumnsToPivot +' into edw_temp.tquote_home_additional_coverage_temp1
			from
			(
			select
			acT.PolicyNumber as quote_no ,act.EffectiveDate ,act.ExpirationDate ,act.TransactionEffectiveDate ,
			tph.quote_history_sk,thl.quote_home_location_sk,thc.quote_home_coverage_sk,
			act.[Number] as transaction_seq_no,act.CreatedDate,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value]
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join edw_core.tquote_history tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.[Number]
				left join edw_core.tquote_home_location thl on thl.quote_no=act.PolicyNumber
				left join edw_core.tquote_home_coverage thc on thc.quote_no=act.PolicyNumber
						and thc.effective_dt=act.EffectiveDate and thc.transaction_seq_no=act.[Number]
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null 
				and act.[Stage]  IN (''QUOTE'',''POLICY'')
				and atvo.ObjectType in (''Homeowner'',''Condo'')
				and pr.ProductLine = ''PersonalLines''
				and act.CreatedDate > @last_source_extract_ts
				-- )

			) as t
			pivot 
			(
				max(Value) FOR Field IN ('+ @ColumnsToPivot +')
			) as pivottable
			'
			EXECUTE sp_executesql @sql, N'@last_source_extract_ts DATETIME2(7)', @last_source_extract_ts = @last_source_extract_ts;

			WITH extended_liability_loc_ct AS (	
				select 
					act.PolicyNumber as qte_no, act.EffectiveDate as eff_dt, act.[Number] as tran_seq_no, count(atvo.ObjectGroupIdentifier) as extended_liability_location_ct
				from edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				where
					act.PolicyNumber is not null 
					and act.[Stage]  IN ('QUOTE','POLICY')
					and atvo.ObjectType in ('ExtendedLiabilityLocation')
					and p.ProductLine = 'PersonalLines'
					and act.CreatedDate > @last_source_extract_ts
				group by act.PolicyNumber, act.EffectiveDate, act.[Number]
			)

			INSERT INTO edw_core.tquote_home_additional_coverage
			(
			quote_no,effective_dt,expiration_dt,transaction_seq_no
			,quote_home_location_sk,quote_home_coverage_sk,quote_history_sk,central_reporting_fire_alarm_in
			,central_reporting_burglar_alarm_in,twentyfour_hour_doorman_in,lobby_surveillance_camera_in
			,locked_or_manned_elevators_in,twentyfour_hour_signal_continuity_in,guard_gated_community_in
			,guard_community_patrol_service_in,home_safe_in,fulltime_live_in_caretaker_in,gas_leak_detector_in
			,lightning_protection_in,low_temperature_monitoring_device_in,backup_generator_in
			,external_perimeter_gate_in,external_perimeter_security,water_leak_detection_system
			,residential_sprinkler_system_in,business_property_increase_in,business_property_increase_limit_amt
			,deductible_waiver_large_losses_in,deductible_waiver_large_losses_limit_amt,earthquake_coverage_extension_in
			,earthquake_coverage_extension_deductible,earthquake_coverage_extension_loss_assessment_in
			,earthquake_coverage_extension_loss_assessment_limit_amt,fungi_bacteria_increase_in,fungi_bacteria_increase_limit
			,fungi_bacteria_liability_extension_in,home_systems_protection_in,home_systems_protection_limit_amt
			,increased_incidental_business_threshold_in,increased_incidental_business_threshold_limit_amt
			,landscaping_coverage_increased_limits_in,
			landscaping_coverage_increased_plant_limit_amt
			,landscaping_coverage_increased_aggregate_limit,landscaping_coverage_sleet_and_weight_of_ice_and_snow_coverage_limit_amt
			,landscaping_coverage_wind_and_hail_coverage_limit_amt,law_ordinance_coverage_increase_in
			,law_ordinance_coverage_increased_limit,loss_assessment_increase_in,loss_assessment_increase_limit_amt
			,serviceline_protection_in,thoroughbred_horse_liability_extension_in,no_of_horses,home_cyber_protection_coverage_in
			,home_cyber_protection_coverage_deductible,home_cyber_protection_coverage_limit_amt
			,offpremises_other_permanent_structures_extension_in,offpremises_other_permanent_structures_extension_desc
			,agreed_value_in
			,backup_of_sewers_limit_in,contents_extended_replacement_cost_in,contents_extended_replacement_cost_limit_amt
			,coverage_for_piers_wharves_and_docks_due_to_weight_of_ice_or_snow_in
			,coverage_for_piers_wharves_and_docks_due_to_weight_of_ice_or_snow_limit_amt
			,damage_to_property_of_others_increased_limit_amt,debris_removal_broadaned_tree_removal_in
			,earthquake_endorsement_in,earthquake_endorsement_deductible
			,escaped_liquid_fuel_liability_limit_amt
			,escaped_liquid_fuel_remediation_coverage_in,escaped_liquid_fuel_remediation_liability_limit_amt
			,escaped_liquid_fuel_remediation_risk_class_no,
			fortified_roof_upgrade_in,home_daycare_coverage_in
			,identity_theft_in
			,pollutants_or_contimination_extension_in,
			 pollutants_or_contimination_tankage,pollutants_or_contimination_tank_construction
			,pollutants_or_contimination_tank_location,pollutants_or_contimination_tank_type
			,residence_held_in_trust_in,sinkhole_collapse_in,sinkhole_coverage_extension_in
			,supplemental_loss_assessment_coverage_in,supplemental_loss_assessment_coverage_additional_locations
			,supplemental_loss_assessment_coverage_premises
			,workercompensation_liability_in
			,workercompensation_liability_fulltime_employees_ct,workercompensation_liability_occurance_limit_amt
			,workercompensation_liability_parttime_employees_ct,guaranteed_replacement_cost_in
			,replacement_cost_coverage_in,roof_covering_full_reconstruction_cost_coverage_in
			,additional_replacement_cost_coverage_in,additional_replacement_cost_coverage_with_wildfire_in
			,dwelling_reconstruction_cost_coverage_in,extended_replacement_cost_coverage_with_additional_wildfire_in
			,extended_replacement_cost_coverage_with_wildfire_in,extended_replacement_cost_coverage_in
			,extended_replacement_cost_coverage_option,mine_subsidence_coverage_in
			,mine_subsidence_coverage_limit_amt,minimum_earned_premium_endorsement_in
			,minimum_earned_premium_endorsement_limit_pct,contents_off_premises_loss_exclusion_in
			,premises_liability_limitation_in,manuscript_in
			,amended_settlement_basis_in,additions_and_alterations_extended_replacement_cost_in
			,deletion_of_cosmetic_marring_exclusion_in
			,exclude_wind_in,wind_hail_exclusion_in,roof_exclusion_in,waterdamage_exclusion_in
			,waterdamage_limitation_endorsement_in,waterdamage_limitation_endorsement_limit_amt
			,waterdamage_sublimit,waterdamage_sublimit_amt,underground_resources_exclusion_in
			,named_structures_exclusion_in,named_structures_exclusion_desc,animal_related_liability_exclusion_in
			,libel_slander_exclusion_in,political_activities_exclusion_in
			,equine_related_liability_exclusion_in,canine_liability_exclusion_in
			,named_structures_property_and_liability_exclusion_in,named_structures_property_and_liability_exclusion_desc
			,other_structures_away_from_the_residence_premises_in,other_structures_away_from_the_residence_premises_desc
			,other_structures_on_the_residence_premises_increased_limit_in
			,other_structures_on_the_residence_premises_increased_limit_amt
			,other_structures_on_the_residence_premises_increased_limit_desc,extended_liability_in
			,animal_related_liability_exclusion_desc,change_in_terms_summary_in,
			extended_replacement_cost_coverage_with_additional_wildfire_plus_twentyfive_pc_in,
			home_daycare_coverage_limit_amt,home_daycare_coverage_no_of_children,
			increased_incidental_business_property_in,increased_incidental_business_property_limit_amt,
			loss_assessment_increase_desc,sinkhole_territory,specific_named_structures_property_and_liability_exclusion_in,
			specific_named_structures_property_and_liability_exclusion_desc,underground_water_supplyline_exclusion_in,
			earthquake_score,earthquake_earthmovement_exclusion_ind,
			leed_certification_discount_in,mortgage_free_discount_in,annual_brush_removal_contract_in,
			firewise_community_credit_in,monitored_heat_sensors_in,builders_defect_exclusion_in,
			gated_community_patrol_service, extended_liability_location_ct,
			roof_exclusion_with_ensuing_loss_in,roof_coverage_endorsement_wh_in,roof_coverage_endorsement_ap_in,roof_coverage_endorsement_rv_in,
			fire_station_connected_fire_alarm_in, police_station_connected_burglar_alarm_in, local_fire_alarm_system_in, local_burglar_alarm_system_in, 
			automatic_smoke_detectors_in, automatic_sprinkler_system, emergency_extension_notice_in,trampoline_liability_exclusion_in, fine_arts_exclusion_in, 
			screen_enclosure_coverage_in, screen_enclosure_limit_amt, matching_undamaged_property_in, matching_undamaged_property_limit_amt,
			roof_covering_coverage_limitation_all_peril_loss_settlement_endorsement_in, all_peril_roof_covering_coverage_limitation_loss_settlement_endorsement_in,
			wildfire_protection_enrollment_in ,site_scheduling_contact_nm ,site_scheduling_phone_no ,
			site_scheduling_email ,emergency_contact_nm ,emergency_contact_phone_no ,emergency_contact_email ,gate_code ,
			primary_home_risk_address,primary_home_policy_effective_dt,primary_home_policy_expiration_dt,
			primary_home_carrier_nm,primary_home_coverage_a_threshold,fortified_roof_upgrade_endorsement_in,
			fortified_roof_program_discount_amt, non_program_discount_amt,
			full_extended_replacement_cost_in, risk_score_water_non_weather, risk_score_water_weather,
			risk_score_water_backup, risk_score_wind_hail, risk_score_other, risk_score_lightning,risk_score_theft,
			risk_score_liability, risk_score_hurricane, risk_score_wildfire, risk_score_sinkhole_mine,risk_score_all_perils, risk_score_fire,
			theft_or_loss_general_conditions_endorsement_in, animal_related_liability_endorsement_in,automatic_seismic_shutoff_valve_in,
			all_peril_roof_covering_coverage_CW_in,
			source_system_sk,create_ts,update_ts,etl_audit_sk
			)
			SELECT
			quote_no
           ,EffectiveDate AS effective_dt
           ,ExpirationDate AS expiration_dt
           ,transaction_seq_no AS transaction_seq_no
           ,quote_home_location_sk
           ,quote_home_coverage_sk AS home_coverage_sk
           ,quote_history_sk
           ,CentralReportingFireAlarm AS central_reporting_fire_alarm_in
           ,CentralReportingBurglarAlarm AS central_reporting_burglar_alarm_in
           ,HourDoorman AS twentyfour_hour_doorman_in
           ,LobbySurveillanceCamera AS lobby_surveillance_camera_in
           ,LockedOrMannedElevators AS locked_or_manned_elevators_in
           ,SignalContinuity AS twentyfour_hour_signal_continuity_in
           ,GuardGatedCommunity AS guard_gated_community_in
           ,GuardCommunityPatrolService AS guard_community_patrol_service_in
           ,HomeSafe AS home_safe_in
           ,FulltimeLiveInCaretaker AS fulltime_live_in_caretaker_in
           ,GasLeakDetector AS gas_leak_detector_in
           ,LightningProtection AS lightning_protection_in
           ,LowTemperatureMonitoringDevice AS low_temperature_monitoring_device_in
           ,BackupGenerator AS backup_generator_in
           ,ExternalPerimeterGate AS external_perimeter_gate_in
           ,ExternalPerimeterSecurity AS external_perimeter_landscaping_coverage_increased_limits_insecurity
           ,WaterLeakDetectionSystem AS water_leak_detection_system
           ,ResidentialSprinklerSystem as residential_sprinkler_system_in
           ,BusinessPropertyIncrease as business_property_increase_in
           ,BusinessPropertyIncreaseLimit AS business_property_increase_limit_amt
           ,DeductibleWaiverLargeLosses AS deductible_waiver_large_losses_in
           ,DeductibleWaiverLargeLossesLimit AS deductible_waiver_large_losses_limit_amt
           ,EarthquakeCoverageExtension AS earthquake_coverage_extension_in
           ,EarthquakeCoverageExtensionDeductible AS earthquake_coverage_extension_deductible
           ,EarthquakeCoverageExtensionLossAssessment AS earthquake_coverage_extension_loss_assessment_in
           ,EarthquakeCoverageExtensionLossAssessmentLimit AS earthquake_coverage_extension_loss_assessment_limit_amt
           ,FungiBacteriaIncrease AS fungi_bacteria_increase_in
           ,FungiBacteriaIncreaseLimit AS fungi_bacteria_increase_limit
           ,FungiBacteriaLiabilityExtension AS fungi_bacteria_liability_extension_in
           ,HomeSystemsProtection AS home_systems_protection_in
           ,HomeSystemsProtectionLimit AS home_systems_protection_limit_amt
           ,IncreasedIncidentalBusinessThreshold AS increased_incidental_business_threshold_in
           ,IncreasedIncidentalBusinessThresholdLimit AS increased_incidental_business_threshold_limit_amt
           ,LandscapingCoverageIncreasedLimits AS landscaping_coverage_increased_limits_in
          ,LandscapingCoverageIncreasedPlantLimit AS landscaping_coverage_increased_plant_limit_amt
           ,LandscapingCoverageIncreasedAggregateLimit AS landscaping_coverage_increased_aggregate_limit
           ,LandscapingCoverageSleetAndWeightofIceAndSnowCoverage AS landscaping_coverage_sleet_and_weight_of_ice_and_snow_coverage_limit_amt
           ,LandscapingCoverageWindAndHailCoverage AS landscaping_coverage_wind_and_hail_coverage_limit_amt
           ,LawOrdinanceCoverageIncrease AS law_ordinance_coverage_increase_in
           ,LawOrdinanceCoverageIncreasedLimit AS law_ordinance_coverage_increased_limit
           ,LossAssessmentIncrease AS loss_assessment_increase_in
           ,LossAssessmentIncreaseLimit AS loss_assessment_increase_limit_amt
           ,ServiceLineProtection AS serviceline_protection_in
           ,ThoroughbredHorseLiabilityExtension AS thoroughbred_horse_liability_extension_in
           ,NumberOfHorses AS no_of_horses
           ,HomeCyberProtectionCoverage AS home_cyber_protection_coverage_in
           ,HomeCyberProtectionCoverageDeductible AS home_cyber_protection_coverage_deductible
           ,HomeCyberProtectionCoverageLimit AS home_cyber_protection_coverage_limit_amt
           ,OffPremisesOtherPermanentStructuresExtension AS offpremises_other_permanent_structures_extension_in
           ,OffPremisesOtherPermanentStructuresExtensionDescription AS offpremises_other_permanent_structures_extension_desc
           ,AgreedValue AS agreed_value_in
			,BackUpOfSewersLimit AS backup_of_sewers_limit_in
           ,ContentsExtendedReplacementCost AS contents_extended_replacement_cost_in
		   ,ContentsExtendedReplacementCostLimit AS contents_extended_replacement_cost_limit_amt
           ,CoverageForPiersWharvesAndDocksDueToWeightOfIceOrSnow AS coverage_for_piers_wharves_and_docks_due_to_weight_of_ice_or_snow_in
           ,CoverageForPiersWharvesAndDocksDueToWeightOfIceOrSnowLimit AS coverage_for_piers_wharves_and_docks_due_to_weight_of_ice_or_snow_limit_amt
           ,NULL AS damage_to_property_of_others_increased_limit_amt
           ,DebrisRemovalBroadanedTreeRemoval AS debris_removal_broadaned_tree_removal_in
           ,EarthquakeEndorsement AS earthquake_endorsement_in
           ,EarthquakeEndorsementDeductible AS earthquake_endorsement_deductible
          ,EscapedLiquidFuelLimitOfLiability AS escaped_liquid_fuel_liability_limit_amt
           ,EscapedLiquidFuelRemediationCoverage AS escaped_liquid_fuel_remediation_coverage_in
           ,EscapedLiquidFuelRemediationLimitOfLiability AS escaped_liquid_fuel_remediation_liability_limit_amt
           ,EscapedLiquidFuelRemediationRiskClassNumber AS escaped_liquid_fuel_remediation_risk_class_no
           ,FortifiedRoofUpgrade AS fortified_roof_upgrade_in
           ,HomeDayCareCoverage AS home_daycare_coverage_in
           ,IdentityTheft AS identity_theft_in
           ,PollutantsOrContiminationExtension AS pollutants_or_contimination_extension_in
           ,PollutantsOrContiminationTankAge AS pollutants_or_contimination_tankage
           ,PollutantsOrContiminationTankConstruction AS pollutants_or_contimination_tank_construction
           ,PollutantsOrContiminationTankLocation AS pollutants_or_contimination_tank_location
           ,PollutantsOrContiminationTankType AS pollutants_or_contimination_tank_type
            ,ResidenceHeldInTrust AS residence_held_in_trust_in
           ,SinkholeCollapse AS sinkhole_collapse_in
           ,SinkholeCoverageExtension AS sinkhole_coverage_extension_in
           ,SupplementalLossAssessmentCoverage AS supplemental_loss_assessment_coverage_in
           ,SupplementalLossAssessmentCoverageAdditionalLocations AS supplemental_loss_assessment_coverage_additional_locations
           ,SupplementalLossAssessmentCoveragePremises AS supplemental_loss_assessment_coverage_premises
          ,WorkerCompensationLiability AS workercompensation_liability_in
           ,WorkerCompensationLiabilityFullTimeEmployees AS workercompensation_liability_fulltime_employees_ct
           ,WorkerCompensationLiabilityOccuranceLimit AS workercompensation_liability_occurance_limit_amt
           ,WorkerCompensationLiabilityPartTimeEmployees AS workercompensation_liability_parttime_employees_ct
           ,GuaranteedReplacementCost AS guaranteed_replacement_cost_in
           ,ReplacementCostCoverage AS replacement_cost_coverage_in
           ,RoofCoveringFullReconstructionCostCoverage AS roof_covering_full_reconstruction_cost_coverage_in
           ,AdditionalReplacementCostCoverage AS additional_replacement_cost_coverage_in
           ,AdditionalReplacementCostCoverageWithWildfire AS additional_replacement_cost_coverage_with_wildfire_in
           ,DwellingReconstructionCostCoverage AS dwelling_reconstruction_cost_coverage_in
           ,ExtendedReplacementCostCoverageWithAdditionalWildfire AS extended_replacement_cost_coverage_with_additional_wildfire_in
           ,ExtendedReplacementCostCoverageWithWildfire AS extended_replacement_cost_coverage_with_wildfire_in
           ,ExtendedReplacementCostCoverage AS extended_replacement_cost_coverage_in
           ,ExtendedReplacementCostCoverageOption AS extended_replacement_cost_coverage_option
           ,MineSubsidenceCoverage AS mine_subsidence_coverage_in
           ,MineSubsidenceCoverageLimit AS mine_subsidence_coverage_limit_amt
           ,MinimumEarnedPremiumEndorsement AS minimum_earned_premium_endorsement_in
           ,MinimumEarnedPremiumEndorsementLimit AS minimum_earned_premium_endorsement_limit_pct
           ,ContentsOffPremisesLossExclusion AS contents_off_premises_loss_exclusion_in
           ,PremisesLiabilityLimitation AS premises_liability_limitation_in
           ,IncludeManuscript AS manuscript_in
           ,AmendedSettlementBasis AS amended_settlement_basis_in
           ,AdditionsAndAlterationsExtendedReplacementCost AS additions_and_alterations_extended_replacement_cost_in     
           ,DeletionofCosmeticMarringExclusion AS deletion_of_cosmetic_marring_exclusion_in
           ,ExcludeWind AS exclude_wind_in
           ,WindHailExclusion AS wind_hail_exclusion_in
           ,RoofExclusion AS roof_exclusion_in
           ,WaterDamageExclusion AS waterdamage_exclusion_in
           ,WaterDamageLimitationEndorsement AS waterdamage_limitation_endorsement_in
           ,WaterDamageLimitationEndorsementLimit AS waterdamage_limitation_endorsement_limit_amt
           ,WaterDamageSubLimit AS waterdamage_sublimit
           ,WaterDamageSubLimitAmount AS waterdamage_sublimit_amt
           ,UndergroundResourcesExclusion AS underground_resources_exclusion_in
           ,NamedStructuresExclusion AS named_structures_exclusion_in
           ,NamedStructuresExclusionDescription AS named_structures_exclusion_desc
           ,AnimalRelatedLiabilityExclusion AS animal_related_liability_exclusion_in
           ,LibelSlanderExclusion AS libel_slander_exclusion_in
           ,PoliticalActivitiesExclusion AS political_activities_exclusion_in
           ,EquineRelatedLiabilityExclusion AS equine_related_liability_exclusion_in
           ,CanineLiabilityExclusion AS canine_liability_exclusion_in
           ,NamedStructuresPropertyAndLiabilityExclusion AS named_structures_property_and_liability_exclusion_in
           ,NamedStructuresPropertyAndLiabilityExclusionDescription AS named_structures_property_and_liability_exclusion_desc
           ,OtherStructuresAwayFromTheResidencePremises AS other_structures_away_from_the_residence_premises_in
           ,OtherStructuresAwayFromTheResidencePremisesDescription AS other_structures_away_from_the_residence_premises_desc
           ,OtherStructuresOnTheResidencePremisesIncreasedLimit AS other_structures_on_the_residence_premises_increased_limit_in
           ,OtherStructuresOnTheResidencePremisesIncreasedLimitAmount AS other_structures_on_the_residence_premises_increased_limit_amt
           ,OtherStructuresOnTheResidencePremisesIncreasedLimitDescription AS other_structures_on_the_residence_premises_increased_limit_desc
           ,ExtendedLiability AS extended_liability_in
		   ,AnimalRelatedLiabilityExclusion AS animal_related_liability_exclusion_desc
		   ,AddChangeInTermsSummary AS change_in_terms_summary_in
		   ,ExtendedReplacementCostCoverageWithAdditionalWildfirePlusTwentyFivePercent AS extended_replacement_cost_coverage_with_additional_wildfire_plus_twentyfive_pc_in
           ,HomeDayCareCoverageLimit AS home_daycare_coverage_limit_amt
		   ,HomeDayCareCoverage AS home_daycare_coverage_no_of_children
		   ,IncreasedIncidentalBusinessProperty AS increased_incidental_business_property_in
		   ,IncreasedIncidentalBusinessPropertyLimit AS increased_incidental_business_property_limit_amt
		   ,LossAssessmentIncreaseDescription AS loss_assessment_increase_desc
		   ,sinkholeterritory AS sinkhole_territory
		   ,SpecificNamedStructuresPropertyandLiabilityExclusion AS specific_named_structures_property_and_liability_exclusion_in
		   ,SpecificNamedStructuresPropertyandLiabilityExclusionDescription AS specific_named_structures_property_and_liability_exclusion_desc
		   ,UndergroundResourcesExclusion AS underground_water_supplyline_exclusion_in
		   ,EarthquakeScore AS earthquake_score
		   ,EarthquakeandEarthMovementExclusion AS earthquake_earthmovement_exclusion_ind 
		   ,LEEDCertificationDiscount AS leed_certification_discount_in
		   ,MortgageFreeDiscount AS mortgage_free_discount_in 
		   ,AnnualBrushRemovalContract AS annual_brush_removal_contract_in
		   ,FirewiseCommunityCredit AS firewise_community_credit_in
		   ,MonitoredHeatSensors AS monitored_heat_sensors_in
		   ,BuildersDefectExclusion AS builders_defect_exclusion_in
		   ,GatedCommunityPatrolService AS gated_community_patrol_service
		   ,b.extended_liability_location_ct
		   ,RoofExclusionWEnsuingLoss AS roof_exclusion_with_ensuing_loss_in
		   ,RoofCoverageEndorsementWH AS roof_coverage_endorsement_wh_in
		   ,RoofCoverageEndorsementAP AS roof_coverage_endorsement_ap_in
		   ,RoofCoverageEndorsementRV AS roof_coverage_endorsement_rv_in
		   ,FireStationConnectedFireAlarm as fire_station_connected_fire_alarm_in
		   ,PoliceStationConnectedBurglarAlarm as  police_station_connected_burglar_alarm_in
		   ,LocalFireAlarmSystem as local_fire_alarm_system_in
		   ,LocalBurglarAlarmSystem as local_burglar_alarm_system_in
		   ,AutomaticSmokeDetectors as automatic_smoke_detectors_in
		   ,AutomaticSprinklerSystem as automatic_sprinkler_system_in
		   ,EmergencyExtensionNotice as emergency_extension_notice_in
		   ,TrampolineExclusion as trampoline_liability_exclusion_in
		   ,FineArtsExclusion as fine_arts_exclusion_in
		   ,ScreenEnclosureCoverage as screen_enclosure_coverage_in
	       ,ScreenEnclosureLimit as screen_enclosure_limit_amt
		   ,MatchingUndamagedProperty as matching_undamaged_property_in 
		   ,MatchingUndamagedPropertyLimit as matching_undamaged_property_limit_amt
		   ,RoofCoveringCoverageLimitationCW as roof_covering_coverage_limitation_all_peril_loss_settlement_endorsement_in
		   ,AllPerilRoofCoveringCoverageSP as all_peril_roof_covering_coverage_limitation_loss_settlement_endorsement_in
		   ,WildfireProtectionEnrollment as wildfire_protection_enrollment_in
		   ,WFSiteSchedulingContactName as site_scheduling_contact_nm
		   ,WFSiteSchedulingPhoneNumber as site_scheduling_phone_no
		   ,WFSiteSchedulingEmailAddress as site_scheduling_email
		   ,WFEmergencyContactName as emergency_contact_nm
		   ,WFEmergencyContactPhoneNumber as emergency_contact_phone_no
		   ,WFEmergencyContactEmail as emergency_contact_email,WFGateCodes as gate_code
		   ,PrimaryHomeRiskAddress as primary_home_risk_address
		   ,PrimaryHomePolicyEffectiveDate  as primary_home_policy_effective_dt
		   ,PrimaryHomePolicyExpirationDate as primary_home_policy_expiration_dt
		   ,PrimaryHomeCarrierName as primary_home_carrier_nm
		   ,PrimaryHomeCoverageAThreshold as primary_home_coverage_a_threshold
		   ,FortifiedRoofUpgradeEndorsement as fortified_roof_upgrade_endorsement_in
		   ,FortifiedRoofProgramDiscount as fortified_roof_program_discount_amt
		   ,NonProgramDiscount as non_program_discount_amt
		   ,FullExtendedReplacementCostCoverage as full_extended_replacement_cost_in
			,Risk_Score_Water_Non_Weather as risk_score_water_non_weather, Risk_Score_Water_Weather as risk_score_water_weather
			,Risk_Score_Water_Backup as risk_score_water_backup, Risk_Score_Wind_Hail as risk_score_wind_hail
			,Risk_Score_Other as risk_score_other, Risk_Score_Lightning as risk_score_lightning
			,Risk_Score_Theft as risk_score_theft
			,Risk_Score_Liability as risk_score_liability
			,Risk_Score_Hurricane as risk_score_hurricane, Risk_Score_Wildfire as risk_score_wildfire
			,Risk_Score_Sinkhole_Mine as risk_score_sinkhole_mine
			,Risk_Score_All_Perils as risk_score_all_peril
			,Risk_Score_Fire as risk_score_fire
			,TheftOrLossGeneralConditionsEndorsement as theft_or_loss_general_conditions_endorsement_in
			,AnimalRelatedLiabilityEndorsement as animal_related_liability_endorsement_in
			,case when AutomaticSeismicShutOffValve = '' then null else AutomaticSeismicShutOffValve end as automatic_seismic_shutoff_valve_in
			,AllPerilRoofCoveringCoverageCW as all_peril_roof_covering_coverage_CW_in
		   ,source_system_sk
           ,GETDATE() AS create_ts
           ,GETDATE() AS update_ts
           ,@etl_audit_sk AS etl_audit_sk
			FROM
				edw_temp.tquote_home_additional_coverage_temp1 AS a
			LEFT JOIN extended_liability_loc_ct AS b
				ON a.quote_no = b.qte_no
				AND a.EffectiveDate = b.eff_dt
				AND a.transaction_seq_no = b.tran_seq_no

			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_home_additional_coverage_temp1),@last_source_extract_ts);	
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;


			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

			-- Drop temp table
			DROP TABLE IF EXISTS edw_temp.tquote_home_additional_coverage_temp1
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
