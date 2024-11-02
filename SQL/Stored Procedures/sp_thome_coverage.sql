-- ===========================================================================================================================
-- Description: This procedures loads home coverage data
------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------------
--  			Yunus Mohammed					1. Created this procedure 
-- 08/23/23		Architha Gudimalla				2. Added changes for residence type, loss_of_use_pc, total_insured_value_amt
-- 10/02/23		Architha Gudimalla				3. Added replace to remove , from sq footage
-- 10/05/23		Architha Gudimalla				4. Removed TIV update and moved to separate proc
-- 10/13/23		Architha Gudimalla				5. Updated residence type
-- 11/16/23		Architha Gudimalla				6. Added wildfire columns
-- 11/16/23		Architha Gudimalla				7. updated the join for AccountTransactionVersionPremiumfactor
-- 11/30/23		Yunus Mohammed					8. Added new fields
-- 12/06/23		Alberto Almario					9. Added new field WindstormOrHailDeductibleManual
-- 22/02/24		Hernando Gonzalez				10. Added new fields aon_hurricane_reinsurance_margin_amt, aon_hurricane_ceded_loss_amt, aon_hurricane_reinsurance_premium_amt, aon_hurricane_capital_cost_amt, aon_hurricane_cat_score_to_premium_ratio, aon_hurricane_aal_to_premium_ratio, aon_hurricane_aal_amt
-- 04/02/24		Yunus Mohammed					11. Updated wind_derived_deductible logic
-- 12/06/24		Alberto Almario					12. Added new filed nc_bureau_rate
-- 07/09/24		Yunus Mohammed					13. Added new fields stated_limits_policy_in and risk_sharing_policy_in
-- 08/13/24		Yunus Mohammed					14. Updated wind_derived_deductible logic
-- 08/20/24		Yunus Mohammed					15. Updated wind_derived_deductible logic
-- 09/03/24		Yunus Mohammed					16. Added new field no_of_family_units_in_structures.	
-- 10/02/24		Yunus Mohammed					17. Added new field fortified_roof_credit
-- 31/10/24		Hernando Gonzalez				18. AD-7487 | Added new fields facultative_reinsurance_in, layered_limits_in, 100_pc_dwelling_limit_value_amt, 100_pc_other_structures_limit_value_amt, 100_pc_contents_limit_value_amt, 100_pc_loss_of_use_value_amt, facultative_attachment_point, facultative_limit_amt, facultative_ceded_premium_amt, facultative_reinsurer_nm, coverage_layer, coverage_layer_placed_pc, coverage_layer_limit_amt, newly_purchased_home_in, target_closing_dt, current_policy_anniversary_dt, current_underlying_company_nm, new_client_for_agency_in
-- =========================================================================================================================== 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_thome_coverage]

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
			--AG - commented below on 20230823
			--pd.[Name],pdo.ObjectType,
			pdof.Field 
			--AG - commented below on 20230823
			--,pdof.[Group]
			FROM
			edw_stage.Product pd
			INNER JOIN edw_stage.[ProductObject] pdo on pd.Id=pdo.ProductId
			INNER JOIN edw_stage.[ProductObjectField] pdof on pdo.Id=pdof.ProductObjectId 
			--AG - added condo on 20230823
			WHERE pd.[Name] in ('Homeowners','Condo','Inspection')
			--AG - added condo on 20230823
			AND pdo.ObjectType in ('Homeowner','Condo','Inspection')
		) as temp

		-- remove last comma
		SET @ColumnsToPivot = LEFT(@ColumnsToPivot, LEN(@ColumnsToPivot) - 1);

		declare @sql nvarchar(max)
		drop table if exists edw_temp.thome_coverage_temp1
		SET @sql ='select PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transactiondate,transaction_seq_no,source_system_sk,
		IssuedDate,policy_history_sk,home_location_sk,product_name,
		FactorMethod, Factor, Retention, Reason,
		'+ @ColumnsToPivot +' into edw_temp.thome_coverage_temp1
			from
			(
			select
			act.PolicyNumber ,act.EffectiveDate ,act.ExpirationDate ,act.TransactionEffectiveDate ,
			tph.policy_history_sk,thl.home_location_sk,
			act.policychangenumber as transaction_seq_no, act.IssuedDate as transactiondate,act.IssuedDate, pr.name product_name,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value],
			atvpf.FactorMethod, atvpf.Factor, atvpf.Retention, atvpf.Reason
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionPremium atvp on atv.Id=atvp.AccountTransactionVersionId
				left join edw_stage.AccountTransactionVersionPremiumfactor atvpf on atvp.Id=atvpf.AccountTransactionVersionPremiumId and atvpf.coverage = ''Homeowners''
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId 
				left join edw_core.tpolicy_history tph on tph.policy_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.policychangenumber
				left join edw_core.thome_location thl on thl.policy_no=act.PolicyNumber
						and thl.effective_dt=act.EffectiveDate
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null and
				act.[State] =''ISSUED''
				and atvo.ObjectType in (''Homeowner'',''Condo'',''Inspection'')
				and pr.ProductLine = ''PersonalLines''
				and act.IssuedDate > @last_source_extract_ts
			) as t
			pivot 
			(
				max(Value) FOR Field IN ('+ @ColumnsToPivot +')
			) as pivottable
			'
			EXECUTE sp_executesql @sql, N'@last_source_extract_ts datetime2(7)', @last_source_extract_ts = @last_source_extract_ts
		
			INSERT INTO [edw_core].[thome_coverage]
			(
				policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_dt,transaction_seq_no,
				home_location_sk,policy_history_sk,dwelling_limit_amt,other_structures_limit_amt,contents_limit_amt,
				loss_of_use_limit_amt,loss_of_use_option, loss_of_use_pc, --loss_of_use_pc_derived,
				personal_liability_limit_amt,medical_payments_limit_amt,exclude_inflation_factor_in,aop_deductible,hurricane_deductible,
				water_deductible,wildfire_deductible,wind_derived_deductible,no_of_mortgagees,prior_claim_last5yr_in,
				prior_nonwater_claim_ct,prior_water_claim_ct, distance_to_coast,
				distance_to_fire_hydrant_feet,distance_to_fire_station_miles,fire_protection,occupancy_type,protection_class,earthquake_zone,
				terrain_cd,windborne_debris_region_in,windpool_eligibility_in,sinkhole_risk_level,sinkhole_distance_to_nearest_miles,
				total_finished_square_feet,construction_type,basement_type,active_renovation,renovation_anticipated_completion_dt,
				ulstandard,unit_floor,built_year,electrical_updated_year,hvac_updated_year,	plumbing_updated_year,roof_updated_year,
				no_of_stories,shear_wave_velocity,barn_on_property_in,barn_value_amt,bceg_cd,windspeed_of_design,
				hail_resistant_rating_in, hurricane_fortification_in,
				mmi,swimming_pool_in,hazard_severity,
				distance_to_very_high_fuel_feet,distance_to_high_fuel_feet,distance_to_moderate_fuel_feet,
				no_of_wildfire_occurrences,no_of_wildfire_near_occurrences,nearest_distance_to_perimeter,
				combustible_wood_siding_in,combustible_deck_or_attached_structure_in,firewood_or_combustibles_stored_against_home_in,
				defensible_space_in,woodshake_or_shingle_roof_in,speciality_ember_resistant_venting_in,
				exterior_wildfire_sprinklers_in,eaves_or_enclosed_eaves_in,permanently_installed_spray_system_in,
				portable_fire_break_system_in,gutter_guards_in,bark_mulch_within_ten_feet_of_any_structure_in,
				flammable_vegetation_within_ten_feet_of_any_structure_in,opening_protection,
				roof_cover_deck,roof_covering,roof_deck_attachment,roof_geometry,roof_system_in,
				roof_wall_attachment,solar_feature_desc,secondary_water_resistance,
				residence_type,total_insured_value_amt,
				rating_territory_cd,bceg_credit_pc,distance_to_shore,wildfire_score,within_500feet_from_shore_in,
				--earthquake_damage_limt_amt,earthquake_shake,
				hurricane_or_named_storm_deductible,named_storm_deductible,tornado_or_hailstorm_deductible,
				wind_or_hailstorm_deductible,
				premium_adjustment_method, premium_adjustment_factor, premium_adjustment_retention, premium_adjustment_retention_reason,
				reinsurance_designation, reinsurance_layered_program_in, reinsurance_attachment_limit_amt, reinsurance_total_tiv_amt,
				wildfire_threat, wildfire_hazard_severity,aop_deductible_manual,water_deductible_manual,wildfire_deductible_manual,wind_or_hailstorm_deductible_manual,
				aon_hurricane_cat_score_amt, aon_hurricane_reinsurance_margin_amt, aon_hurricane_ceded_loss_amt, aon_hurricane_reinsurance_premium_amt, aon_hurricane_capital_cost_amt, aon_hurricane_cat_score_to_premium_ratio, aon_hurricane_aal_to_premium_ratio, aon_hurricane_aal_amt,
				waive_inspection_in, waive_inspection_reason, inspection_note, rms_reviewed_in,
				nc_bureau_rate,stated_limits_policy_in,risk_sharing_policy_in,no_of_family_units_in_structures,fortified_roof_credit,
				facultative_reinsurance_in, layered_limits_in, [dwelling_limit_100_pc_value_amt], [other_structures_limit_100_pc_value_amt], [contents_limit_100_pc_value_amt], [loss_of_use_100_pc_value_amt], facultative_attachment_point, facultative_limit_amt, facultative_ceded_premium_amt, facultative_reinsurer_nm, coverage_layer, coverage_layer_placed_pc, coverage_layer_limit_amt, newly_purchased_home_in, target_closing_dt, current_policy_anniversary_dt, current_underlying_company_nm, new_client_for_agency_in,
				source_system_sk,create_ts,update_ts,etl_audit_sk
			)
			SELECT
				tthc.PolicyNumber AS policy_no,tthc.EffectiveDate AS effective_dt,tthc.ExpirationDate AS expiration_dt,
				tthc.TransactionEffectiveDate AS transaction_effective_dt,tthc.transactiondate AS transaction_dt,
				tthc.transaction_seq_no AS transaction_seq_no,tthc.home_location_sk AS home_location_sk,policy_history_sk,
				tthc.CoverageA AS dwelling_limit_amt,tthc.CoverageB AS other_structures_limit_amt,tthc.CoverageC AS contents_limit_amt,
				tthc.CoverageD AS loss_of_use_limit_amt,CoverageDOption AS loss_of_use_option, 
				CoverageDPercentage AS loss_of_use_pc, 
				--AG - added on 20230823 
				--AG - updated on 20230912
				/*CASE
					WHEN CoverageDOption in ('Reasonable and Necessary Expenses','reasonableAndNecessaryExpenses') THEN 0.2
					WHEN CoverageDOption like '%.%' THEN  cast(CoverageDOption as float)/100
					WHEN CoverageDOption like '%' THEN  cast(replace(CoverageDOption,'%','') as float)/100
					WHEN CoverageDOption is null and CoverageD is not null and tthc.CoverageA > 0 then cast(CoverageD as decimal)/tthc.CoverageA
					WHEN CoverageDOption is null and CoverageD is not null and tthc.CoverageC > 0 then cast(CoverageD as decimal)/tthc.CoverageC
					WHEN CoverageDOption is null and CoverageD is null THEN 0.0  
				END as loss_of_use_pc_derived*/
				tthc.CoverageE AS personal_liability_limit_amt,
				REPLACE(REPLACE(tthc.CoverageF,'$',''),',','') AS medical_payments_limit_amt,
				tthc.ExcludeInflationFactor AS exclude_inflation_factor_in,tthc.AopDeductible AS aop_deductible,
				tthc.HurricaneDeductible AS hurricane_deductible,
				tthc.WaterDeductible AS water_deductible,
				tthc.WildfireDeductible AS wildfire_deductible,
				CASE
					WHEN ISNULL(tthc.HurricaneDeductible,'') != '' AND tthc.HurricaneDeductible like '%Exclude Wind%' THEN 'Exclude'
					WHEN ISNULL(tthc.HurricaneDeductible,'') != '' AND (tthc.WindStormOrHailDeductible like '%aop applies%' or tthc.WindStormOrHailDeductible like '%aopApplies%') THEN 'AOP Applies'
					WHEN ISNULL(tthc.HurricaneOrNamedStormDeductible,'') != '' AND tthc.HurricaneOrNamedStormDeductible like '%Exclude Wind%' THEN 'Exclude'
					WHEN ISNULL(tthc.HurricaneOrNamedStormDeductible,'') != '' AND (tthc.HurricaneOrNamedStormDeductible like '%aop applies%' or tthc.HurricaneOrNamedStormDeductible like '%aopApplies%') THEN 'AOP Applies'
					WHEN ISNULL(tthc.NamedStormDeductible,'') != '' AND tthc.NamedStormDeductible like '%Exclude Wind%' THEN 'Exclude'
					WHEN ISNULL(tthc.NamedStormDeductible,'') != '' AND (tthc.NamedStormDeductible like '%aop applies%' or tthc.NamedStormDeductible like '%aopApplies%') THEN 'AOP Applies'
					WHEN ISNULL(tthc.TornadoorHailstormDeductible,'') != '' AND tthc.TornadoorHailstormDeductible like '%Exclude Wind%' THEN 'Exclude'
					WHEN ISNULL(tthc.TornadoorHailstormDeductible,'') != '' AND (tthc.TornadoorHailstormDeductible like '%aop applies%' or tthc.TornadoorHailstormDeductible like '%aopApplies%') THEN 'AOP Applies'
					WHEN ISNULL(tthc.WindStormOrHailDeductible ,'') != '' AND tthc.WindStormOrHailDeductible like '%Exclude Wind%' THEN 'Exclude'
					WHEN ISNULL(tthc.WindStormOrHailDeductible,'') != '' AND
					(
						tthc.WindStormOrHailDeductible like '%aop applies%' OR 
						tthc.WindStormOrHailDeductible like '%aopApplies%' OR
						tthc.WindStormOrHailDeductible like '%AOP Deductible%'

					) THEN 'AOP Applies'
					--
					WHEN ISNULL(tthc.HurricaneDeductible,'')  NOT IN ('','0') THEN HurricaneDeductible
					WHEN ISNULL(tthc.HurricaneOrNamedStormDeductible,'') NOT IN ('','0') THEN HurricaneOrNamedStormDeductible
					WHEN ISNULL(tthc.NamedStormDeductible,'') NOT IN ('','0') THEN NamedStormDeductible
					WHEN ISNULL(tthc.TornadoorHailstormDeductible,'') NOT IN ('','0') THEN TornadoorHailstormDeductible
					WHEN ISNULL(tthc.WindStormOrHailDeductible ,'') NOT IN ('','0','Other') THEN WindStormOrHailDeductible
					
					WHEN ISNULL(tthc.WindstormOrHailDeductibleManual ,'') NOT IN ('','0') THEN WindstormOrHailDeductibleManual
				END AS wind_derived_deductible,
				tthc.NumberOfMortgagees AS no_of_mortgagees,
				tthc.PriorClaims AS prior_claim_last5yr_in,tthc.PriorNonWaterClaims AS prior_nonwater_claim_ct,
				tthc.PriorWaterClaims AS prior_water_claim_ct,
				tthc.DistanceToCoast AS distance_to_coast,
				tthc.DistanceToHydrantFeet AS distance_to_fire_hydrant_feet,
				tthc.DistanceToStationMiles AS distance_to_fire_station_miles,
				tthc.FireProtection AS fire_protection ,tthc.Occupancy AS occupancy_type,
				tthc.ProtectionClass AS protection_class,
				tthc.EarthquakeZone AS earthquake_zone,tthc.Terrain AS terrain_cd,
				tthc.WindBorneDebrisRegion AS windborne_debris_region_in,
				tthc.WindPoolEligibility AS windpool_eligibility_in,
				tthc.SinkholeRiskLevel AS sinkhole_risk_level,
				tthc.SinkHoleDistanceToNearestMiles AS sinkhole_distance_to_nearest_miles,
				-- added below on  10/02/23		Architha Gudimalla
				replace(tthc.SquareFootage,',','') as SquareFootage,tthc.constructionType AS construction_type,
				tthc.BasementType AS basement_type,tthc.ActiveRenovation AS active_renovation,
				tthc.ActiveRenovationAnticipatedCompletionDate AS renovation_anticipated_completion_dt,
				tthc.ULStandard AS ulstandard,tthc.UnitFloor AS unit_floor,tthc.YearBuilt AS built_year,
				tthc.YearElectricalUpdated AS electrical_updated_year,tthc.YearHvacUpdated AS [hvac_updated_year],
				tthc.YearPlumbingUpdated AS plumbing_updated_year,
				tthc.YearRoofUpdated AS roof_updated_year,tthc.NumberOfStories AS no_of_stories,
				tthc.ShearWaveVelocity AS shear_wave_velocity,
				tthc.BarnOnProperty AS barn_on_property_in,tthc.BarnValue AS barn_value_amt,
				tthc.BCEG AS bceg_cd,tthc.WindSpeedOfDesign AS windspeed_of_design,
				tthc.HailResistantRating AS hail_resistant_rating_in,
				tthc.HurricaneFortification AS hurricane_fortification_in,
				tthc.MMI,tthc.SwimmingPool AS swimming_pool_in,
				tthc.WildfireHazardSeverity AS hazard_severity,
				tthc.WildfireDistanceToVeryHighFuelFeet AS distance_to_very_high_fuel_feet,
				tthc.WildfireDistanceToHighFuelFeet AS distance_to_high_fuel_feet,
				tthc.WildfireDistanceToModerateFuelFeet AS distance_to_moderate_fuel_feet,
				tthc.WildfireNumberOfOccurrences AS no_of_wildfire_occurrences,
				tthc.WildfireNumberOfOccurrencesNear AS no_of_wildfire_near_occurrences,
				tthc.WildfireNearestDistanceToPerimeter AS nearest_distance_to_perimeter,
				tthc.WildfireCombustibleWoodSiding AS combustible_wood_siding_in,
				tthc.WildfireCombustibleDeckOrAttachedStructure AS combustible_deck_or_attached_structure_in,
				tthc.WildfireFireWoodOrCombustiblesStoredAgainstHome AS firewood_or_combustibles_stored_against_home_in,
				tthc.WildfireDefensibleSpace AS defensible_space_in,
				tthc.WildfireWoodShakeOrShingleRoof AS woodshake_or_shingle_roof_in,
				tthc.WildfireSpecialityEmberResistantVenting AS speciality_ember_resistant_venting_in,
				tthc.WildfireExteriorWildfireSprinklers AS exterior_wildfire_sprinklers_in,
				tthc.WildfireEavesorEnclosedEaves AS eaves_or_enclosed_eaves_in,
				tthc.WildfirePermanentlyInstalledSpraySystem AS permanently_installed_spray_system_in,
				tthc.WildfirePortableFireBreakSystem AS portable_fire_break_system_in,
				tthc.WildfireGutterGuards AS gutter_guards_in,
				tthc.WildfireBarkMulchWithinTenFeetofAnyStructure AS bark_mulch_within_ten_feet_of_any_structure_in,
				tthc.WildfireFlammableVegetationWithinTenFeetofAnyStructure AS flammable_vegetation_within_ten_feet_of_any_structure_in,
				tthc.OpeningProtection AS opening_protection,
				tthc.RoofCoverDeck AS roof_cover_deck,
				tthc.RoofCovering AS roof_covering,
				tthc.RoofDeckAttachment AS roof_deck_attachment,
				tthc.RoofGeometry AS roof_geometry,
				tthc.RoofSystem AS roof_system_in,
				tthc.RoofWallAttachment AS roof_wall_attachment,
				tthc.SolarPanels AS solar_feature_desc,
				tthc.SecondaryWaterResistance AS secondary_water_resistance,
				--AG - added on 20230823
				case when tthc.product_name = 'Homeowners' then 'Homeowners' else tthc.ResidenceType 
				end as residence_type , 
				--AG - added on 20230823
				0 as total_insured_value_amt,
				tthc.RatingTerritory AS rating_territory_cd,
				case when tthc.BCEGCreditPercent = '#N/A' then null else tthc.BCEGCreditPercent end AS bceg_credit_pc,
				tthc.DistanceToShore AS distance_to_shore,
				tthc.WildfireScore AS wildfire_score,
				tthc.Within500Feet AS within_500feet_from_shore_in,
				--tthc.EarthquakeDamage AS earthquake_damage_limt_amt,
				--tthc.EarthquakeShake AS earthquake_shake,
				tthc.HurricaneOrNamedStormDeductible AS hurricane_or_named_storm_deductible,
				tthc.NamedStormDeductible AS named_storm_deductible,
				tthc.TornadoorHailstormDeductible AS tornado_or_hailstorm_deductible
				,tthc.WindStormOrHailDeductible AS wind_or_hailstorm_deductible,
				tthc.FactorMethod, tthc.Factor, tthc.Retention, tthc.Reason
				,tthc.ReinsuranceDesignation AS ReinsuranceDesignation
				,tthc.ReinsuranceLayedProgram, tthc.ReinsuranceAttachmentLimit, tthc.ReinsuranceTotalTIV, 
				tthc.WildfireThreat, tthc.WildfireHazardSeverity,
				tthc.AOPDeductiblemanual, tthc.Waterdeductiblemanual,tthc.wildfiredeductiblemanual, tthc.WindstormOrHailDeductibleManual,
				tthc.CATModeling_CATScore, tthc.CATModeling_ReinsuranceMargin, tthc.CATModeling_CededLoss, tthc.CATModeling_ReinsurancePremium, 
				tthc.CATModeling_CapitalCost, tthc.CATModeling_CATScoreToPremiumRatio_Hurricane, tthc.CATModeling_AALToPremium, tthc.AAL, 
				tthc.WaiveInspection as waive_inspection_in, tthc.WaiveReason as waive_inspection_reason, tthc.InspectionNotes as inspection_note, 
				tthc.RMSReviewed as rms_reviewed_in, 
				tthc.NCRBManualRate as nc_bureau_rate,StatedLimitsPolicy as stated_limits_policy_in, RiskSharingPolicy as risk_sharing_policy_in,
				tthc.NumberofFamilyUnitsinStructure as no_of_family_units_in_structures,
				tthc.FortifiedRoofCredit as fortified_roof_credit,
				tthc.FacultativeReinsurance as facultative_reinsurance_in,
				tthc.LayeredLimits as layered_limits_in,
				tthc.[100PercentCoverageAValue] as [dwelling_limit_100_pc_value_amt],
				tthc.[100PercentCoverageBValue] as [other_structures_limit_100_pc_value_amt],
				tthc.[100PercentCoverageCValue] as [contents_limit_100_pc_value_amt],
				tthc.[100PercentCoverageDValue] as [loss_of_use_100_pc_value_amt],
				tthc.FACAttachmentPoint as facultative_attachment_point,
				tthc.FACLimit as facultative_limit_amt,
				tthc.FACPremiumCeded as facultative_ceded_premium_amt,
				tthc.FACReinsurer as facultative_reinsurer_nm,
				tthc.CoverageLayer as coverage_layer,
				TRY_CAST(REPLACE(tthc.PercentagePlaced, '%', '') AS FLOAT) / 100 AS coverage_layer_placed_pc,
				tthc.LayerLimit as coverage_layer_limit_amt,
				tthc.NewlyPurchasedHome as newly_purchased_home_in,
				tthc.TargetClosingDate as target_closing_dt,
				tthc.CurrentPolicyAnniversaryDate as current_policy_anniversary_dt,
				CONCAT(tthc.HomeInsuranceCompany, ' ', tthc.OtherCarrierName) as current_underlying_company_nm,
				tthc.NewClientForTheAgency as new_client_for_agency_in,
				source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
			FROM
				edw_temp.thome_coverage_temp1 AS tthc

			SET @rows_affected=@@ROWCOUNT;  

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.thome_coverage_temp1),@last_source_extract_ts);	
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

			-- Drop temp table
			DROP TABLE IF EXISTS edw_temp.thome_coverage_temp1
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