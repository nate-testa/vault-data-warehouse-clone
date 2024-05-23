-- ===========================================================================================================================
-- Author:		Yunus Mohammed 
-- Description: This procedures loads home quote coverage data wip
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/07/2024 			Yunus Mohammed				1. Created this procedure 
-- 05/23/2024 			Yunus Mohammed				2. Updated join with AccountPremiumFactor
-- =========================================================================================================================== 
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tquote_home_coverage_wip]

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
		drop table if exists edw_temp.tquote_home_coverage_wip_temp1
		SET @sql ='select quote_no,EffectiveDate,ExpirationDate,0 as transaction_seq_no,source_system_sk,
		quote_history_sk,quote_home_location_sk,product_name,CreatedDate,UpdatedDate,
		FactorMethod, Factor, Retention, Reason,
		'+ @ColumnsToPivot +' into edw_temp.tquote_home_coverage_wip_temp1
			from
			(
			select
			acc.PolicyNumber as quote_no,acc.EffectiveDate ,acc.ExpirationDate ,acc.TransactionEffectiveDate ,
			tqh.quote_history_sk,thql.quote_home_location_sk,
			0 as transaction_seq_no,acc.CreatedDate,acc.UpdatedDate, pr.name product_name,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,accvof.Field,accvof.[Value],
			accpf.FactorMethod, accpf.Factor, accpf.Retention, accpf.Reason
			from
				edw_stage.Account acc
				inner join edw_stage.Product p on p.Id=acc.ProductId
				INNER JOIN edw_stage.[AccountObject] AS accvo ON accvo.AccountId = acc.Id
                INNER JOIN edw_stage.[AccountObjectField] AS accvof ON accvof.ObjectId = accvo.id
                left join edw_stage.Accountpremium ap on ap.AccountId=acc.id                
                left join edw_stage.AccountPremiumFactor accpf on accpf.AccountPremiumId=ap.id and accpf.coverage = ''Homeowners''
				and accpf.factor is not null
                left join edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
				left join edw_core.tquote_home_location thql on thql.quote_no=acc.PolicyNumber
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				and not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
				and accvo.ObjectType in (''Homeowner'',''Condo'',''Inspection'')
				and pr.ProductLine = ''PersonalLines''
				and greatest(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts
			) as t
			pivot 
			(
				max(Value) FOR Field IN ('+ @ColumnsToPivot +')
			) as pivottable
			'
			EXECUTE sp_executesql @sql, N'@last_source_extract_ts datetime2(7)', @last_source_extract_ts = @last_source_extract_ts
			
			MERGE [edw_core].[tquote_home_coverage] AS Target
			USING 
			(
				SELECT
				tthc.quote_no AS quote_no,tthc.EffectiveDate AS effective_dt,tthc.ExpirationDate AS expiration_dt,
				tthc.transaction_seq_no AS transaction_seq_no,tthc.quote_home_location_sk,quote_history_sk,
				tthc.CoverageA AS dwelling_limit_amt,tthc.CoverageB AS other_structures_limit_amt,tthc.CoverageC AS contents_limit_amt,
				tthc.CoverageD AS loss_of_use_limit_amt,CoverageDOption AS loss_of_use_option, 
				CoverageDPercentage AS loss_of_use_pc, 				
				tthc.CoverageE AS personal_liability_limit_amt,
				REPLACE(REPLACE(tthc.CoverageF,'$',''),',','') AS medical_payments_limit_amt,
				tthc.ExcludeInflationFactor AS exclude_inflation_factor_in,tthc.AopDeductible AS aop_deductible,
				tthc.HurricaneDeductible AS hurricane_deductible,
				tthc.WaterDeductible AS water_deductible,
				tthc.WildfireDeductible AS wildfire_deductible,
				CASE
					WHEN ISNULL(tthc.HurricaneDeductible,'') != '' THEN HurricaneDeductible
					WHEN ISNULL(tthc.HurricaneOrNamedStormDeductible,'') != '' THEN HurricaneOrNamedStormDeductible
					WHEN ISNULL(tthc.NamedStormDeductible,'') != '' THEN NamedStormDeductible
					WHEN ISNULL(tthc.TornadoorHailstormDeductible,'') != '' THEN TornadoorHailstormDeductible
					WHEN ISNULL(tthc.WindStormOrHailDeductible ,'') != '' THEN WindStormOrHailDeductible
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
				replace(tthc.SquareFootage,',','') as total_finished_square_feet,tthc.constructionType AS construction_type,
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
				case when tthc.product_name = 'Homeowners' then 'Homeowners' else tthc.ResidenceType 
				end as residence_type ,
				0 as total_insured_value_amt,
				tthc.RatingTerritory AS rating_territory_cd,
				case when tthc.BCEGCreditPercent = '#N/A' then null else tthc.BCEGCreditPercent end AS bceg_credit_pc,
				tthc.DistanceToShore AS distance_to_shore,
				tthc.WildfireScore AS wildfire_score,
				tthc.Within500Feet AS within_500feet_from_shore_in,
				tthc.HurricaneOrNamedStormDeductible AS hurricane_or_named_storm_deductible,
				tthc.NamedStormDeductible AS named_storm_deductible,
				tthc.TornadoorHailstormDeductible AS tornado_or_hailstorm_deductible,
				tthc.WindStormOrHailDeductible AS wind_or_hailstorm_deductible, 
				tthc.FactorMethod as premium_adjustment_method, tthc.Factor as premium_adjustment_factor, tthc.Retention as premium_adjustment_retention, 
				tthc.Reason as premium_adjustment_retention_reason,
				tthc.ReinsuranceDesignation as reinsurance_designation, tthc.ReinsuranceLayedProgram as reinsurance_layered_program_in, 
				tthc.ReinsuranceAttachmentLimit as reinsurance_attachment_limit_amt, tthc.ReinsuranceTotalTIV as reinsurance_total_tiv_amt, 
				tthc.WildfireThreat as wildfire_threat, tthc.WildfireHazardSeverity as wildfire_hazard_severity,
				tthc.AOPDeductiblemanual as aop_deductible_manual, tthc.Waterdeductiblemanual as water_deductible_manual,
				tthc.wildfiredeductiblemanual as wildfire_deductible_manual,tthc.WindstormOrHailDeductibleManual as wind_or_hailstorm_deductible_manual,
				tthc.CATModeling_CATScore as aon_hurricane_cat_score_amt, tthc.CATModeling_ReinsuranceMargin as aon_hurricane_reinsurance_margin_amt, 
				tthc.CATModeling_CededLoss as aon_hurricane_ceded_loss_amt, tthc.CATModeling_ReinsurancePremium as aon_hurricane_reinsurance_premium_amt,
				tthc.CATModeling_CapitalCost as aon_hurricane_capital_cost_amt, tthc.CATModeling_CATScoreToPremiumRatio_Hurricane  as aon_hurricane_cat_score_to_premium_ratio,
				tthc.CATModeling_AALToPremium as aon_hurricane_aal_to_premium_ratio, tthc.AAL as aon_hurricane_aal_amt, 
				tthc.WaiveInspection as waive_inspection_in, tthc.WaiveReason as waive_inspection_reason, tthc.InspectionNotes as inspection_note, tthc.RMSReviewed as rms_reviewed_in,
				source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
			FROM
				edw_temp.tquote_home_coverage_wip_temp1 AS tthc
			) AS Source
			ON Source.quote_no = Target.[quote_no] and Source.effective_dt = Target.effective_dt and Source.transaction_seq_no = Target.transaction_seq_no
			WHEN NOT MATCHED BY Target THEN			
			INSERT
			(
				quote_no,effective_dt,expiration_dt,transaction_seq_no,
				quote_home_location_sk,quote_history_sk,dwelling_limit_amt,other_structures_limit_amt,contents_limit_amt,
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
				wildfire_threat, wildfire_hazard_severity,
				aop_deductible_manual,water_deductible_manual,wildfire_deductible_manual,wind_or_hailstorm_deductible_manual,
				aon_hurricane_cat_score_amt, aon_hurricane_reinsurance_margin_amt, aon_hurricane_ceded_loss_amt, aon_hurricane_reinsurance_premium_amt, aon_hurricane_capital_cost_amt,
				aon_hurricane_cat_score_to_premium_ratio, aon_hurricane_aal_to_premium_ratio, aon_hurricane_aal_amt, 
				waive_inspection_in, waive_inspection_reason, inspection_note, rms_reviewed_in,
				source_system_sk,create_ts,update_ts,etl_audit_sk
			)
			VALUES
			(

				quote_no,effective_dt,expiration_dt,transaction_seq_no,
				quote_home_location_sk,quote_history_sk,dwelling_limit_amt,other_structures_limit_amt,contents_limit_amt,
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
				wildfire_threat, wildfire_hazard_severity,
				aop_deductible_manual,water_deductible_manual,wildfire_deductible_manual,wind_or_hailstorm_deductible_manual,
				aon_hurricane_cat_score_amt, aon_hurricane_reinsurance_margin_amt, aon_hurricane_ceded_loss_amt, aon_hurricane_reinsurance_premium_amt, 
				aon_hurricane_capital_cost_amt, aon_hurricane_cat_score_to_premium_ratio, aon_hurricane_aal_to_premium_ratio, aon_hurricane_aal_amt, 
				waive_inspection_in, waive_inspection_reason, inspection_note, rms_reviewed_in,
				source_system_sk,create_ts,update_ts,etl_audit_sk
			)
			WHEN MATCHED THEN UPDATE
			SET
			[target].expiration_dt = [source].expiration_dt,
			[target].quote_home_location_sk = [source].quote_home_location_sk,
			[target].quote_history_sk = [source].quote_history_sk,
			[target].residence_type = [source].residence_type,
			[target].dwelling_limit_amt = [source].dwelling_limit_amt,
			[target].other_structures_limit_amt = [source].other_structures_limit_amt,
			[target].contents_limit_amt = [source].contents_limit_amt,
			[target].loss_of_use_limit_amt = [source].loss_of_use_limit_amt,
			[target].loss_of_use_option = [source].loss_of_use_option,
			[target].loss_of_use_pc = [source].loss_of_use_pc,
			[target].personal_liability_limit_amt = [source].personal_liability_limit_amt,
			[target].medical_payments_limit_amt = [source].medical_payments_limit_amt,
			[target].total_insured_value_amt = [source].total_insured_value_amt,
			[target].exclude_inflation_factor_in = [source].exclude_inflation_factor_in,
			[target].aop_deductible = [source].aop_deductible,
			[target].water_deductible = [source].water_deductible,
			[target].hurricane_deductible = [source].hurricane_deductible,
			[target].hurricane_or_named_storm_deductible = [source].hurricane_or_named_storm_deductible,
			[target].named_storm_deductible = [source].named_storm_deductible,
			[target].tornado_or_hailstorm_deductible = [source].tornado_or_hailstorm_deductible,
			[target].wind_or_hailstorm_deductible = [source].wind_or_hailstorm_deductible,
			[target].wind_derived_deductible = [source].wind_derived_deductible,
			[target].wildfire_deductible = [source].wildfire_deductible,
			[target].no_of_mortgagees = [source].no_of_mortgagees,
			[target].prior_claim_last5yr_in = [source].prior_claim_last5yr_in,
			[target].prior_nonwater_claim_ct = [source].prior_nonwater_claim_ct,
			[target].prior_water_claim_ct = [source].prior_water_claim_ct,
			[target].rating_territory_cd = [source].rating_territory_cd,
			[target].distance_to_coast = [source].distance_to_coast,
			[target].distance_to_shore = [source].distance_to_shore,
			[target].within_500feet_from_shore_in = [source].within_500feet_from_shore_in,
			[target].distance_to_fire_hydrant_feet = [source].distance_to_fire_hydrant_feet,
			[target].distance_to_fire_station_miles = [source].distance_to_fire_station_miles,
			[target].fire_protection = [source].fire_protection,
			[target].occupancy_type = [source].occupancy_type,
			[target].protection_class = [source].protection_class,
			[target].earthquake_zone = [source].earthquake_zone,
			[target].terrain_cd = [source].terrain_cd,
			[target].windborne_debris_region_in = [source].windborne_debris_region_in,
			[target].windpool_eligibility_in = [source].windpool_eligibility_in,
			[target].sinkhole_risk_level = [source].sinkhole_risk_level,
			[target].sinkhole_distance_to_nearest_miles = [source].sinkhole_distance_to_nearest_miles,
			[target].total_finished_square_feet = [source].total_finished_square_feet,
			[target].construction_type = [source].construction_type,
			[target].basement_type = [source].basement_type,
			[target].active_renovation = [source].active_renovation,
			[target].renovation_anticipated_completion_dt = [source].renovation_anticipated_completion_dt,
			[target].ulstandard = [source].ulstandard,
			[target].unit_floor = [source].unit_floor,
			[target].built_year = [source].built_year,
			[target].electrical_updated_year = [source].electrical_updated_year,
			[target].hvac_updated_year = [source].hvac_updated_year,
			[target].plumbing_updated_year = [source].plumbing_updated_year,
			[target].roof_updated_year = [source].roof_updated_year,
			[target].no_of_stories = [source].no_of_stories,
			[target].shear_wave_velocity = [source].shear_wave_velocity,
			[target].barn_on_property_in = [source].barn_on_property_in,
			[target].barn_value_amt = [source].barn_value_amt,
			[target].bceg_cd = [source].bceg_cd,
			[target].bceg_credit_pc = [source].bceg_credit_pc,
			[target].windspeed_of_design = [source].windspeed_of_design,
			[target].hail_resistant_rating_in = [source].hail_resistant_rating_in,
			[target].hurricane_fortification_in = [source].hurricane_fortification_in,
			[target].mmi = [source].mmi,
			[target].swimming_pool_in = [source].swimming_pool_in,
			[target].wildfire_score = [source].wildfire_score,
			[target].hazard_severity = [source].hazard_severity,
			[target].distance_to_very_high_fuel_feet = [source].distance_to_very_high_fuel_feet,
			[target].distance_to_high_fuel_feet = [source].distance_to_high_fuel_feet,
			[target].distance_to_moderate_fuel_feet = [source].distance_to_moderate_fuel_feet,
			[target].no_of_wildfire_occurrences = [source].no_of_wildfire_occurrences,
			[target].no_of_wildfire_near_occurrences = [source].no_of_wildfire_near_occurrences,
			[target].nearest_distance_to_perimeter = [source].nearest_distance_to_perimeter,
			[target].combustible_wood_siding_in = [source].combustible_wood_siding_in,
			[target].combustible_deck_or_attached_structure_in = [source].combustible_deck_or_attached_structure_in,
			[target].firewood_or_combustibles_stored_against_home_in = [source].firewood_or_combustibles_stored_against_home_in,
			[target].defensible_space_in = [source].defensible_space_in,
			[target].woodshake_or_shingle_roof_in = [source].woodshake_or_shingle_roof_in,
			[target].speciality_ember_resistant_venting_in = [source].speciality_ember_resistant_venting_in,
			[target].exterior_wildfire_sprinklers_in = [source].exterior_wildfire_sprinklers_in,
			[target].eaves_or_enclosed_eaves_in = [source].eaves_or_enclosed_eaves_in,
			[target].permanently_installed_spray_system_in = [source].permanently_installed_spray_system_in,
			[target].portable_fire_break_system_in = [source].portable_fire_break_system_in,
			[target].gutter_guards_in = [source].gutter_guards_in,
			[target].bark_mulch_within_ten_feet_of_any_structure_in = [source].bark_mulch_within_ten_feet_of_any_structure_in,
			[target].flammable_vegetation_within_ten_feet_of_any_structure_in = [source].flammable_vegetation_within_ten_feet_of_any_structure_in,
			[target].opening_protection = [source].opening_protection,
			[target].roof_cover_deck = [source].roof_cover_deck,
			[target].roof_covering = [source].roof_covering,
			[target].roof_deck_attachment = [source].roof_deck_attachment,
			[target].roof_geometry = [source].roof_geometry,
			[target].roof_system_in = [source].roof_system_in,
			[target].roof_wall_attachment = [source].roof_wall_attachment,
			[target].solar_feature_desc = [source].solar_feature_desc,
			[target].secondary_water_resistance = [source].secondary_water_resistance,
			[target].premium_adjustment_method = [source].premium_adjustment_method,
			[target].premium_adjustment_factor = [source].premium_adjustment_factor,
			[target].premium_adjustment_retention = [source].premium_adjustment_retention,
			[target].premium_adjustment_retention_reason = [source].premium_adjustment_retention_reason,
			[target].reinsurance_designation = [source].reinsurance_designation,
			[target].reinsurance_layered_program_in = [source].reinsurance_layered_program_in,
			[target].reinsurance_attachment_limit_amt = [source].reinsurance_attachment_limit_amt,
			[target].reinsurance_total_tiv_amt = [source].reinsurance_total_tiv_amt,			
			[target].wildfire_threat = [source].wildfire_threat,
			[target].wildfire_hazard_severity = [source].wildfire_hazard_severity,
			[target].aop_deductible_manual = [source].aop_deductible_manual,
			[target].water_deductible_manual = [source].water_deductible_manual,
			[target].wildfire_deductible_manual = [source].wildfire_deductible_manual,
			[target].wind_or_hailstorm_deductible_manual = [source].wind_or_hailstorm_deductible_manual,
			[target].aon_hurricane_cat_score_amt = [source].aon_hurricane_cat_score_amt,
			[target].aon_hurricane_reinsurance_margin_amt = [source].aon_hurricane_reinsurance_margin_amt,
			[target].aon_hurricane_ceded_loss_amt = [source].aon_hurricane_ceded_loss_amt,
			[target].aon_hurricane_reinsurance_premium_amt = [source].aon_hurricane_reinsurance_premium_amt,
			[target].aon_hurricane_capital_cost_amt = [source].aon_hurricane_capital_cost_amt,
			[target].aon_hurricane_cat_score_to_premium_ratio = [source].aon_hurricane_cat_score_to_premium_ratio,
			[target].aon_hurricane_aal_to_premium_ratio = [source].aon_hurricane_aal_to_premium_ratio,
			[target].aon_hurricane_aal_amt = [source].aon_hurricane_aal_amt,
			[target].waive_inspection_in = [source].waive_inspection_in,
			[target].waive_inspection_reason = [source].waive_inspection_reason,
			[target].inspection_note = [source].inspection_note,
			[target].rms_reviewed_in = [source].rms_reviewed_in,
			[target].update_ts = GETDATE();

			SET @rows_affected=@@ROWCOUNT; 

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate,UpdatedDate)) FROM edw_temp.tquote_home_coverage_wip_temp1),@last_source_extract_ts);	
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

			-- Drop temp table
			DROP TABLE IF EXISTS edw_temp.tquote_home_coverage_wip_temp1
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