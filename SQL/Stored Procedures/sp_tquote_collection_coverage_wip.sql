-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Coverage 
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 09/05/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_collection_coverage_wip]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_coverage_wip_temp1];

		DECLARE @ColumnsToPivot NVARCHAR(MAX)=''
		SELECT @ColumnsToPivot+=QUOTENAME(Field) + ','
		FROM
		(
			SELECT DISTINCT
				pd.[Name],pdo.ObjectType,pdof.Field,pdof.[Group]
			FROM
				edw_stage.Product pd
			INNER JOIN edw_stage.[ProductObject] pdo on pd.Id=pdo.ProductId
			INNER JOIN edw_stage.[ProductObjectField] pdof on pdo.Id=pdof.ProductObjectId
			WHERE
				pd.[Name] = 'Collections'
				AND pdo.ObjectType='Collection'
				AND pd.ProductLine='PersonalLines' --20230717 added
		) AS ColumnsToPivot_temp

		-- Remove last comma
		SET @ColumnsToPivot = LEFT(@ColumnsToPivot, LEN(@ColumnsToPivot) - 1);
	
		DECLARE @sql NVARCHAR(max)
		SET @sql ='SELECT Id, PolicyNumber as quote_no, EffectiveDate, ExpirationDate
            --,[Number]
            ,0 as [Number]
			,quote_collection_location_sk
			,quote_history_sk			
			,UnoccupiedMoreThanThreeMonths,NumberOfLossesLastThreeYears,ProtectionClass,Terrain,DistanceToCoast,RoofGeometry,RoofCovering,RoofCoverDeck,RoofDeckAttachment,RoofWallAttachment,HailResistantRating,SecondaryWaterResistance,ConstructionType,YearBuilt,FireProtection,OpeningProtection,NumberOfStories,CentralReportingFireAlarm,CentralReportingBurglarAlarm,HomeSafe,FulltimeLiveInCaretaker,BackupGenerator,ResidentialSprinklerSystem,MarketValueScheduledItems,MarketScheduledClassBankVaultedJewelry,MarketScheduledClassCoins,MarketScheduledClassCollectibles,MarketScheduledClassFineArts,MarketScheduledClassFurs,MarketScheduledClassGuns,MarketScheduledClassWorldwideJewelry,MarketScheduledClassMiscellaneous,MarketScheduledClassMusicalInstruments,MarketScheduledClassSilver,MarketScheduledClassStamps,MarketScheduledClassWearableCollectibles,MarketScheduledClassWine,MinimumEarnedPremiumEndorsement,TRY_CONVERT(float, MinimumEarnedPremiumEndorsementLimit) as MinimumEarnedPremiumEndorsementLimit,WardrobeLossPrevention,CompanionCreditHomeowner,AgreedValue,AgreedValueSpecifiedClass,AgreedValueSpecifiedClassBankVaultedJewelry,AgreedValueSpecifiedClassCoins,AgreedValueSpecifiedClassCollectibles,AgreedValueSpecifiedClassFineArts,AgreedValueSpecifiedClassFurs,AgreedValueSpecifiedClassGuns,AgreedValueSpecifiedClassWorldwideJewelry,AgreedValueSpecifiedClassMiscellaneous,AgreedValueSpecifiedClassMusicalInstruments,AgreedValueSpecifiedClassSilver,AgreedValueSpecifiedClassStamps,AgreedValueSpecifiedClassWearableCollectibles,AgreedValueSpecifiedClassWine,AgreedValueSpecifiedItems,AlarmWarranty,BreakageExclusion,TerrorismLimitation,TerrorismLimitationAmount,TheftMysteriousDisappearanceExclusion,TransitLimit,TransitLimitAmount,HurricaneLossExclusion,HurricaneLossLimitation,HurricaneLossLimitationAmount,OutdoorFineArtHurricaneExclusion,TerrorismExclusion,DeletionofCosmeticMarringExclusion,EarthquakeExclusion,EarthquakeDeductibleLossLimitation,EarthquakeDeductibleLossLimitationLimit,HotelMotelExclusion,JewelryOffPremisesLossLimitation,SpoilageExclusion,ChangeinTermsSummary,ChangeinTermsOptions,Manuscript,CoverageDeductible,CoverageDeductibleAmount,HurricaneDeductible,HurricaneDeductibleType,HurricaneDeductibleLimit,EarthquakeDeductible,EarthquakeDeductibleAmount,WildfireDeductible,WildfireDeductibleType,WildfireDeductibleAmount,WildfireBarkMulchWithinTenFeetofAnyStructure,WildfireCombustibleDeckOrAttachedStructure,WildfireCombustibleWoodSiding,WildfireDefensibleSpace,WildfireDistanceToHighFuelFeet,WildfireDistanceToModerateFuelFeet,WildfireDistanceToVeryHighFuelFeet,WildfireEavesorEnclosedEaves,WildfireExteriorWildfireSprinklers,WildfireFireWoodOrCombustiblesStoredAgainstHome,WildfireFlammableVegetationWithinTenFeetofAnyStructure,WildfireGutterGuards,WildfireHazardSeverity,WildfireNearestDistanceToPerimeter,WildfireNumberOfOccurrencesNear,WildfireNumberOfOccurrences,WildfirePermanentlyInstalledSpraySystem,WildfirePortableFireBreakSystem,WildfireSpecialityEmberResistantVenting,WildfireThreat,WildfireWoodShakeOrShingleRoof,CoutureAndWearableCollectiblesClassCouture
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			INTO [edw_temp].[tquote_collection_coverage_wip_temp1]
			FROM
			(
				SELECT acc.Id, acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.[Number]
					,accof.Field, accof.[Value]
					,acco.ObjectType
					,acc.CreatedDate, acc.UpdatedDate
					,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
						  Else 4 --(Metal)
					 end as [source_system_sk] --20230717 added
					,tqh.quote_history_sk,tqcl.quote_collection_location_sk
				FROM
					(
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
					INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
					inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				    inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
					LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
					LEFT JOIN edw_core.tquote_collection_location tqcl on tqcl.quote_no=acc.PolicyNumber						
				WHERE
					p.Name=''Collections''
					and acco.ObjectType = ''Collection''
					and p.ProductLine=''PersonalLines'' --20230717 added
			) AS t
			PIVOT 
			(
				max(Value) FOR Field IN (UnoccupiedMoreThanThreeMonths,NumberOfLossesLastThreeYears,ProtectionClass,Terrain,DistanceToCoast,RoofGeometry,RoofCovering,RoofCoverDeck,RoofDeckAttachment,RoofWallAttachment,HailResistantRating,SecondaryWaterResistance,ConstructionType,YearBuilt,FireProtection,OpeningProtection,NumberOfStories,CentralReportingFireAlarm,CentralReportingBurglarAlarm,HomeSafe,FulltimeLiveInCaretaker,BackupGenerator,ResidentialSprinklerSystem,MarketValueScheduledItems,MarketScheduledClassBankVaultedJewelry,MarketScheduledClassCoins,MarketScheduledClassCollectibles,MarketScheduledClassFineArts,MarketScheduledClassFurs,MarketScheduledClassGuns,MarketScheduledClassWorldwideJewelry,MarketScheduledClassMiscellaneous,MarketScheduledClassMusicalInstruments,MarketScheduledClassSilver,MarketScheduledClassStamps,MarketScheduledClassWearableCollectibles,MarketScheduledClassWine,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,WardrobeLossPrevention,CompanionCreditHomeowner,AgreedValue,AgreedValueSpecifiedClass,AgreedValueSpecifiedClassBankVaultedJewelry,AgreedValueSpecifiedClassCoins,AgreedValueSpecifiedClassCollectibles,AgreedValueSpecifiedClassFineArts,AgreedValueSpecifiedClassFurs,AgreedValueSpecifiedClassGuns,AgreedValueSpecifiedClassWorldwideJewelry,AgreedValueSpecifiedClassMiscellaneous,AgreedValueSpecifiedClassMusicalInstruments,AgreedValueSpecifiedClassSilver,AgreedValueSpecifiedClassStamps,AgreedValueSpecifiedClassWearableCollectibles,AgreedValueSpecifiedClassWine,AgreedValueSpecifiedItems,AlarmWarranty,BreakageExclusion,TerrorismLimitation,TerrorismLimitationAmount,TheftMysteriousDisappearanceExclusion,TransitLimit,TransitLimitAmount,HurricaneLossExclusion,HurricaneLossLimitation,HurricaneLossLimitationAmount,OutdoorFineArtHurricaneExclusion,TerrorismExclusion,DeletionofCosmeticMarringExclusion,EarthquakeExclusion,EarthquakeDeductibleLossLimitation,EarthquakeDeductibleLossLimitationLimit,HotelMotelExclusion,JewelryOffPremisesLossLimitation,SpoilageExclusion,ChangeinTermsSummary,ChangeinTermsOptions,Manuscript,CoverageDeductible,CoverageDeductibleAmount,HurricaneDeductible,HurricaneDeductibleType,HurricaneDeductibleLimit,EarthquakeDeductible,EarthquakeDeductibleAmount,WildfireDeductible,WildfireDeductibleType,WildfireDeductibleAmount,WildfireBarkMulchWithinTenFeetofAnyStructure,WildfireCombustibleDeckOrAttachedStructure,WildfireCombustibleWoodSiding,WildfireDefensibleSpace,WildfireDistanceToHighFuelFeet,WildfireDistanceToModerateFuelFeet,WildfireDistanceToVeryHighFuelFeet,WildfireEavesorEnclosedEaves,WildfireExteriorWildfireSprinklers,WildfireFireWoodOrCombustiblesStoredAgainstHome,WildfireFlammableVegetationWithinTenFeetofAnyStructure,WildfireGutterGuards,WildfireHazardSeverity,WildfireNearestDistanceToPerimeter,WildfireNumberOfOccurrencesNear,WildfireNumberOfOccurrences,WildfirePermanentlyInstalledSpraySystem,WildfirePortableFireBreakSystem,WildfireSpecialityEmberResistantVenting,WildfireThreat,WildfireWoodShakeOrShingleRoof,CoutureAndWearableCollectiblesClassCouture)
			) AS pivottable
			'

		--EXECUTE sp_executesql @sql
		EXECUTE sp_executesql @sql, N'@last_source_extract_ts datetime2(7)', @last_source_extract_ts = @last_source_extract_ts

        MERGE INTO [edw_core].[tquote_collection_coverage] AS TARGET
        USING (
            SELECT
                [quote_no] AS [quote_no]
                ,[EffectiveDate] AS [effective_dt]
                ,[ExpirationDate] AS [expiration_dt]
                ,[Number] AS [transaction_seq_no]
                ,[quote_collection_location_sk] AS [quote_collection_location_sk]
                ,[quote_history_sk] AS [quote_history_sk]
                ,[UnoccupiedMoreThanThreeMonths] AS [unoccupied_more_than_three_months_in]
                ,[NumberOfLossesLastThreeYears] AS [valuable_article_losses_last3_years_ct]
                ,[ProtectionClass] AS [protection_class]
                ,[Terrain] AS [terrain_cd]
                ,[DistanceToCoast] AS [distance_to_coast]
                ,[RoofGeometry] AS [roof_geometry]
                ,[RoofCovering] AS [roof_covering]
                ,[RoofCoverDeck] AS [roof_cover_deck]
                ,[RoofDeckAttachment] AS [roof_deck_Attachment]
                ,[RoofWallAttachment] AS [roof_wall_Attachment]
                ,[HailResistantRating] AS [hail_resistant_rating]
                ,[SecondaryWaterResistance] AS [secondary_water_resistance]
                ,[ConstructionType] AS [construction_type]
                ,[YearBuilt] AS [built_year]
                ,[FireProtection] AS [fire_protection]
                ,[OpeningProtection] AS [opening_protection]
                ,[NumberOfStories] AS [no_of_stories]
                ,[CentralReportingFireAlarm] AS [central_reporting_fire_alarm_in]
                ,[CentralReportingBurglarAlarm] AS [central_reporting_burglar_alarm_in]
                ,[HomeSafe] AS [home_safe_in]
                ,[FulltimeLiveInCaretaker] AS [fulltime_live_in_caretaker_in]
                ,[BackupGenerator] AS [backup_generator_in]
                ,[ResidentialSprinklerSystem] AS [residential_sprinkler_system_in]
                ,[MarketValueScheduledItems] AS [market_value_scheduled_items_coverage_in]
                ,[MarketScheduledClassBankVaultedJewelry] AS [bank_vaulted_jewelry_coverage_in]
                ,[MarketScheduledClassCoins] AS [coins_coverage_in]
                ,[MarketScheduledClassCollectibles] AS [collectibles_coverage_in]
                ,[MarketScheduledClassFineArts] AS [fine_arts_coverage_in]
                ,[MarketScheduledClassFurs] AS [furs_coverage_in]
                ,[MarketScheduledClassGuns] AS [guns_coverage_in]
                ,[MarketScheduledClassWorldwideJewelry] AS [jewelry_coverage_in]
                ,[MarketScheduledClassMiscellaneous] AS [miscellaneous_coverage_in]
                ,[MarketScheduledClassMusicalInstruments] AS [musical_instruments_coverage_in]
                ,[MarketScheduledClassSilver] AS [silver_coverage_in]
                ,[MarketScheduledClassStamps] AS [stamps_coverage_in]
                ,[MarketScheduledClassWearableCollectibles] AS [wearable_collectibles_coverage_in]
                ,[MarketScheduledClassWine] AS [wine_coverage_in]
                ,[MinimumEarnedPremiumEndorsement] AS [minimum_earned_premium_endorsement_in]
                ,[MinimumEarnedPremiumEndorsementLimit] AS [minimum_earned_premium_endorsement_limit_pc]
                ,[WardrobeLossPrevention] AS [wardrobe_loss_prevention_in]
                ,[CompanionCreditHomeowner] AS [companion_credit_homeowner_in]
                ,[AgreedValue] AS [agreed_value_limitations_in]
                ,[AgreedValueSpecifiedClass] AS [agreed_value_specified_class_limitations_in]
                ,[AgreedValueSpecifiedClassBankVaultedJewelry] AS [agreed_value_specified_class_bank_vaulted_jewelry_limitations_in]
                ,[AgreedValueSpecifiedClassCoins] AS [agreed_value_specified_class_coins_limitations_in]
                ,[AgreedValueSpecifiedClassCollectibles] AS [agreed_value_specified_class_collectibles_limitations_in]
                ,[AgreedValueSpecifiedClassFineArts] AS [agreed_value_specified_class_fine_arts_limitations_in]
                ,[AgreedValueSpecifiedClassFurs] AS [agreed_value_specified_class_furs_limitations_in]
                ,[AgreedValueSpecifiedClassGuns] AS [agreed_value_specified_class_guns_limitations_in]
                ,[AgreedValueSpecifiedClassWorldwideJewelry] AS [agreed_value_specified_class_worldwide_jewelry_limitations_in]
                ,[AgreedValueSpecifiedClassMiscellaneous] AS [agreed_value_specified_class_miscellaneous_limitations_in]
                ,[AgreedValueSpecifiedClassMusicalInstruments] AS [agreed_value_specified_class_musicalInstruments_limitations_in]
                ,[AgreedValueSpecifiedClassSilver] AS [agreed_value_specified_class_silver_limitations_in]
                ,[AgreedValueSpecifiedClassStamps] AS [agreed_value_specified_class_stamps_limitations_in]
                ,[AgreedValueSpecifiedClassWearableCollectibles] AS [agreed_value_specified_class_wearable_collectibles_limitations_in]
                ,[AgreedValueSpecifiedClassWine] AS [agreed_value_specified_class_wine_limitations_in]
                ,[AgreedValueSpecifiedItems] AS [agreed_value_specified_items_limitations_in]
                ,[AlarmWarranty] AS [alarm_warranty_limitations_in]
                ,[BreakageExclusion] AS [breakage_exclusion_limitations_in]
                ,[TerrorismLimitation] AS [terrorism_limitations_in]
                ,[TerrorismLimitationAmount] AS [Terrorism_limitations_amt]
                ,[TheftMysteriousDisappearanceExclusion] AS [theft_mysterious_disappearance_exclusion_in]
                ,[TransitLimit] AS [transit_limit_in]
                ,[TransitLimitAmount] AS [transit_limit_amt]
                ,[HurricaneLossExclusion] AS [hurricane_loss_exclusion_in]
                ,[HurricaneLossLimitation] AS [hurricane_loss_limitation_in]
                ,[HurricaneLossLimitationAmount] AS [hurricane_loss_limitation_amt]
                ,[OutdoorFineArtHurricaneExclusion] AS [outdoor_fine_art_hurricane_exclusion_in]
                ,[TerrorismExclusion] AS [terrorism_exclusion_in]
                ,[DeletionofCosmeticMarringExclusion] AS [deletion_of_cosmetic_marring_exclusion_in]
                ,[EarthquakeExclusion] AS [earthquake_exclusion_in]
                ,[EarthquakeDeductibleLossLimitation] AS [earthquake_deductible_loss_limitations_in]
                ,[EarthquakeDeductibleLossLimitationLimit] AS [earthquake_deductible_loss_limitations_limit]
                ,[HotelMotelExclusion] AS [hotel_motel_exclusion_in]
                ,[JewelryOffPremisesLossLimitation] AS [jewelry_off_premises_loss_limitation_in]
                ,[SpoilageExclusion] AS [spoilage_exclusion_in]
                ,[ChangeinTermsSummary] AS [change_in_terms_summary_in]
                ,[ChangeinTermsOptions] AS [change_in_terms_options]
                ,[Manuscript] AS [manuscript_in]
                ,[CoverageDeductible] AS [coverage_deductible_in]
                ,[CoverageDeductibleAmount] AS [coverage_deductible_amt]
                ,[HurricaneDeductible] AS [hurricane_deductible_in]
                ,[HurricaneDeductibleType] AS [hurricane_deductible_type]
                ,[HurricaneDeductibleLimit] AS [hurricane_deductible_amt]
                ,[EarthquakeDeductible] AS [earthquake_deductible_in]
                ,[EarthquakeDeductibleAmount] AS [earthquake_deductible_amt]
                ,[WildfireDeductible] AS [wildfire_deductible_in]
                ,[WildfireDeductibleType] AS [wildfire_deductible_type]
                ,[WildfireDeductibleAmount] AS [wildfire_deductible_amt]
                ,[WildfireBarkMulchWithinTenFeetofAnyStructure] AS [wildfire_bark_mulch_within_ten_feet_of_any_structure_in]
                ,[WildfireCombustibleDeckOrAttachedStructure] AS [wildfire_combustible_deck_or_attached_structure_in]
                ,[WildfireCombustibleWoodSiding] AS [wildfire_combustible_wood_siding_in]
                ,[WildfireDefensibleSpace] AS [wildfire_defensible_space_in]
                ,[WildfireDistanceToHighFuelFeet] AS [wildfire_distance_to_high_fuel_feet]
                ,[WildfireDistanceToModerateFuelFeet] AS [wildfire_distance_to_moderate_fuel_feet]
                ,[WildfireDistanceToVeryHighFuelFeet] AS [wildfire_distance_to_very_high_fuel_feet]
                ,[WildfireEavesorEnclosedEaves] AS [wildfire_eaves_or_enclosed_eaves_in]
                ,[WildfireExteriorWildfireSprinklers] AS [wildfire_exteriorWildfireSprinklers_in]
                ,[WildfireFireWoodOrCombustiblesStoredAgainstHome] AS [wildfire_firewood_or_combustibles_stored_against_home_in]
                ,[WildfireFlammableVegetationWithinTenFeetofAnyStructure] AS [wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in]
                ,[WildfireGutterGuards] AS [wildfire_gutter_guards_in]
                ,[WildfireHazardSeverity] AS [wildfire_hazard_severity]
                ,[WildfireNearestDistanceToPerimeter] AS [wildfire_nearest_distance_to_perimeter]
                ,[WildfireNumberOfOccurrencesNear] AS [wildfire_no_of_occurrences_near]
                ,[WildfireNumberOfOccurrences] AS [wildfire_no_of_occurrences]
                ,[WildfirePermanentlyInstalledSpraySystem] AS [wildfire_permanently_installed_spray_system_in]
                ,[WildfirePortableFireBreakSystem] AS [wildfire_portable_fire_break_system_in]
                ,[WildfireSpecialityEmberResistantVenting] AS [wildfire_speciality_ember_resistant_venting_in]
                ,[WildfireThreat] AS [wildfire_threat]
                ,[WildfireWoodShakeOrShingleRoof] AS [wildfire_wood_shake_or_shingle_roof_in]
                ,[CoutureAndWearableCollectiblesClassCouture] AS [couture_wearable_collectibles_class_in]
                ,[source_system_sk] AS [source_system_sk]
                ,getdate() AS [create_ts]
                ,getdate() AS [update_ts]
                ,@etl_audit_sk AS [etl_audit_sk]
            FROM
                edw_temp.tquote_collection_coverage_wip_temp1
        ) AS SOURCE
        ON
            TARGET.quote_no = SOURCE.quote_no AND
            TARGET.effective_dt = SOURCE.effective_dt AND
            TARGET.transaction_seq_no = SOURCE.transaction_seq_no

        WHEN MATCHED THEN
            UPDATE SET
                TARGET.expiration_dt = SOURCE.expiration_dt,
                TARGET.quote_collection_location_sk = SOURCE.quote_collection_location_sk,
                TARGET.quote_history_sk = SOURCE.quote_history_sk,
                TARGET.unoccupied_more_than_three_months_in = SOURCE.unoccupied_more_than_three_months_in,
                TARGET.valuable_article_losses_last3_years_ct = SOURCE.valuable_article_losses_last3_years_ct,
                TARGET.protection_class = SOURCE.protection_class,
                TARGET.terrain_cd = SOURCE.terrain_cd,
                TARGET.distance_to_coast = SOURCE.distance_to_coast,
                TARGET.roof_geometry = SOURCE.roof_geometry,
                TARGET.roof_covering = SOURCE.roof_covering,
                TARGET.roof_cover_deck = SOURCE.roof_cover_deck,
                TARGET.roof_deck_Attachment = SOURCE.roof_deck_Attachment,
                TARGET.roof_wall_Attachment = SOURCE.roof_wall_Attachment,
                TARGET.hail_resistant_rating = SOURCE.hail_resistant_rating,
                TARGET.secondary_water_resistance = SOURCE.secondary_water_resistance,
                TARGET.construction_type = SOURCE.construction_type,
                TARGET.built_year = SOURCE.built_year,
                TARGET.fire_protection = SOURCE.fire_protection,
                TARGET.opening_protection = SOURCE.opening_protection,
                TARGET.no_of_stories = SOURCE.no_of_stories,
                TARGET.central_reporting_fire_alarm_in = SOURCE.central_reporting_fire_alarm_in,
                TARGET.central_reporting_burglar_alarm_in = SOURCE.central_reporting_burglar_alarm_in,
                TARGET.home_safe_in = SOURCE.home_safe_in,
                TARGET.fulltime_live_in_caretaker_in = SOURCE.fulltime_live_in_caretaker_in,
                TARGET.backup_generator_in = SOURCE.backup_generator_in,
                TARGET.residential_sprinkler_system_in = SOURCE.residential_sprinkler_system_in,
                TARGET.market_value_scheduled_items_coverage_in = SOURCE.market_value_scheduled_items_coverage_in,
                TARGET.bank_vaulted_jewelry_coverage_in = SOURCE.bank_vaulted_jewelry_coverage_in,
                TARGET.coins_coverage_in = SOURCE.coins_coverage_in,
                TARGET.collectibles_coverage_in = SOURCE.collectibles_coverage_in,
                TARGET.fine_arts_coverage_in = SOURCE.fine_arts_coverage_in,
                TARGET.furs_coverage_in = SOURCE.furs_coverage_in,
                TARGET.guns_coverage_in = SOURCE.guns_coverage_in,
                TARGET.jewelry_coverage_in = SOURCE.jewelry_coverage_in,
                TARGET.miscellaneous_coverage_in = SOURCE.miscellaneous_coverage_in,
                TARGET.musical_instruments_coverage_in = SOURCE.musical_instruments_coverage_in,
                TARGET.silver_coverage_in = SOURCE.silver_coverage_in,
                TARGET.stamps_coverage_in = SOURCE.stamps_coverage_in,
                TARGET.wearable_collectibles_coverage_in = SOURCE.wearable_collectibles_coverage_in,
                TARGET.wine_coverage_in = SOURCE.wine_coverage_in,
                TARGET.minimum_earned_premium_endorsement_in = SOURCE.minimum_earned_premium_endorsement_in,
                TARGET.minimum_earned_premium_endorsement_limit_pc = SOURCE.minimum_earned_premium_endorsement_limit_pc,
                TARGET.wardrobe_loss_prevention_in = SOURCE.wardrobe_loss_prevention_in,
                TARGET.companion_credit_homeowner_in = SOURCE.companion_credit_homeowner_in,
                TARGET.agreed_value_limitations_in = SOURCE.agreed_value_limitations_in,
                TARGET.agreed_value_specified_class_limitations_in = SOURCE.agreed_value_specified_class_limitations_in,
                TARGET.agreed_value_specified_class_bank_vaulted_jewelry_limitations_in = SOURCE.agreed_value_specified_class_bank_vaulted_jewelry_limitations_in,
                TARGET.agreed_value_specified_class_coins_limitations_in = SOURCE.agreed_value_specified_class_coins_limitations_in,
                TARGET.agreed_value_specified_class_collectibles_limitations_in = SOURCE.agreed_value_specified_class_collectibles_limitations_in,
                TARGET.agreed_value_specified_class_fine_arts_limitations_in = SOURCE.agreed_value_specified_class_fine_arts_limitations_in,
                TARGET.agreed_value_specified_class_furs_limitations_in = SOURCE.agreed_value_specified_class_furs_limitations_in,
                TARGET.agreed_value_specified_class_guns_limitations_in = SOURCE.agreed_value_specified_class_guns_limitations_in,
                TARGET.agreed_value_specified_class_worldwide_jewelry_limitations_in = SOURCE.agreed_value_specified_class_worldwide_jewelry_limitations_in,
                TARGET.agreed_value_specified_class_miscellaneous_limitations_in = SOURCE.agreed_value_specified_class_miscellaneous_limitations_in,
                TARGET.agreed_value_specified_class_musicalInstruments_limitations_in = SOURCE.agreed_value_specified_class_musicalInstruments_limitations_in,
                TARGET.agreed_value_specified_class_silver_limitations_in = SOURCE.agreed_value_specified_class_silver_limitations_in,
                TARGET.agreed_value_specified_class_stamps_limitations_in = SOURCE.agreed_value_specified_class_stamps_limitations_in,
                TARGET.agreed_value_specified_class_wearable_collectibles_limitations_in = SOURCE.agreed_value_specified_class_wearable_collectibles_limitations_in,
                TARGET.agreed_value_specified_class_wine_limitations_in = SOURCE.agreed_value_specified_class_wine_limitations_in,
                TARGET.agreed_value_specified_items_limitations_in = SOURCE.agreed_value_specified_items_limitations_in,
                TARGET.alarm_warranty_limitations_in = SOURCE.alarm_warranty_limitations_in,
                TARGET.breakage_exclusion_limitations_in = SOURCE.breakage_exclusion_limitations_in,
                TARGET.terrorism_limitations_in = SOURCE.terrorism_limitations_in,
                TARGET.terrorism_limitations_amt = SOURCE.terrorism_limitations_amt,
                TARGET.theft_mysterious_disappearance_exclusion_in = SOURCE.theft_mysterious_disappearance_exclusion_in,
                TARGET.transit_limit_in = SOURCE.transit_limit_in,
                TARGET.transit_limit_amt = SOURCE.transit_limit_amt,
                TARGET.hurricane_loss_exclusion_in = SOURCE.hurricane_loss_exclusion_in,
                TARGET.hurricane_loss_limitation_in = SOURCE.hurricane_loss_limitation_in,
                TARGET.hurricane_loss_limitation_amt = SOURCE.hurricane_loss_limitation_amt,
                TARGET.outdoor_fine_art_hurricane_exclusion_in = SOURCE.outdoor_fine_art_hurricane_exclusion_in,
                TARGET.terrorism_exclusion_in = SOURCE.terrorism_exclusion_in,
                TARGET.deletion_of_cosmetic_marring_exclusion_in = SOURCE.deletion_of_cosmetic_marring_exclusion_in,
                TARGET.earthquake_exclusion_in = SOURCE.earthquake_exclusion_in,
                TARGET.earthquake_deductible_loss_limitations_in = SOURCE.earthquake_deductible_loss_limitations_in,
                TARGET.earthquake_deductible_loss_limitations_limit = SOURCE.earthquake_deductible_loss_limitations_limit,
                TARGET.hotel_motel_exclusion_in = SOURCE.hotel_motel_exclusion_in,
                TARGET.jewelry_off_premises_loss_limitation_in = SOURCE.jewelry_off_premises_loss_limitation_in,
                TARGET.spoilage_exclusion_in = SOURCE.spoilage_exclusion_in,
                TARGET.change_in_terms_summary_in = SOURCE.change_in_terms_summary_in,
                TARGET.change_in_terms_options = SOURCE.change_in_terms_options,
                TARGET.manuscript_in = SOURCE.manuscript_in,
                TARGET.coverage_deductible_in = SOURCE.coverage_deductible_in,
                TARGET.coverage_deductible_amt = SOURCE.coverage_deductible_amt,
                TARGET.hurricane_deductible_in = SOURCE.hurricane_deductible_in,
                TARGET.hurricane_deductible_type = SOURCE.hurricane_deductible_type,
                TARGET.hurricane_deductible_amt = SOURCE.hurricane_deductible_amt,
                TARGET.earthquake_deductible_in = SOURCE.earthquake_deductible_in,
                TARGET.earthquake_deductible_amt = SOURCE.earthquake_deductible_amt,
                TARGET.wildfire_deductible_in = SOURCE.wildfire_deductible_in,
                TARGET.wildfire_deductible_type = SOURCE.wildfire_deductible_type,
                TARGET.wildfire_deductible_amt = SOURCE.wildfire_deductible_amt,
                TARGET.wildfire_bark_mulch_within_ten_feet_of_any_structure_in = SOURCE.wildfire_bark_mulch_within_ten_feet_of_any_structure_in,
                TARGET.wildfire_combustible_deck_or_attached_structure_in = SOURCE.wildfire_combustible_deck_or_attached_structure_in,
                TARGET.wildfire_combustible_wood_siding_in = SOURCE.wildfire_combustible_wood_siding_in,
                TARGET.wildfire_defensible_space_in = SOURCE.wildfire_defensible_space_in,
                TARGET.wildfire_distance_to_high_fuel_feet = SOURCE.wildfire_distance_to_high_fuel_feet,
                TARGET.wildfire_distance_to_moderate_fuel_feet = SOURCE.wildfire_distance_to_moderate_fuel_feet,
                TARGET.wildfire_distance_to_very_high_fuel_feet = SOURCE.wildfire_distance_to_very_high_fuel_feet,
                TARGET.wildfire_eaves_or_enclosed_eaves_in = SOURCE.wildfire_eaves_or_enclosed_eaves_in,
                TARGET.wildfire_exteriorWildfireSprinklers_in = SOURCE.wildfire_exteriorWildfireSprinklers_in,
                TARGET.wildfire_firewood_or_combustibles_stored_against_home_in = SOURCE.wildfire_firewood_or_combustibles_stored_against_home_in,
                TARGET.wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in = SOURCE.wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in,
                TARGET.wildfire_gutter_guards_in = SOURCE.wildfire_gutter_guards_in,
                TARGET.wildfire_hazard_severity = SOURCE.wildfire_hazard_severity,
                TARGET.wildfire_nearest_distance_to_perimeter = SOURCE.wildfire_nearest_distance_to_perimeter,
                TARGET.wildfire_no_of_occurrences_near = SOURCE.wildfire_no_of_occurrences_near,
                TARGET.wildfire_no_of_occurrences = SOURCE.wildfire_no_of_occurrences,
                TARGET.wildfire_permanently_installed_spray_system_in = SOURCE.wildfire_permanently_installed_spray_system_in,
                TARGET.wildfire_portable_fire_break_system_in = SOURCE.wildfire_portable_fire_break_system_in,
                TARGET.wildfire_speciality_ember_resistant_venting_in = SOURCE.wildfire_speciality_ember_resistant_venting_in,
                TARGET.wildfire_threat = SOURCE.wildfire_threat,
                TARGET.wildfire_wood_shake_or_shingle_roof_in = SOURCE.wildfire_wood_shake_or_shingle_roof_in,
                TARGET.couture_wearable_collectibles_class_in = SOURCE.couture_wearable_collectibles_class_in,
                TARGET.update_ts = SOURCE.update_ts,
                TARGET.etl_audit_sk = SOURCE.etl_audit_sk

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_collection_location_sk,
                quote_history_sk, unoccupied_more_than_three_months_in, valuable_article_losses_last3_years_ct,
                protection_class, terrain_cd, distance_to_coast, roof_geometry, roof_covering, roof_cover_deck,
                roof_deck_Attachment, roof_wall_Attachment, hail_resistant_rating, secondary_water_resistance,
                construction_type, built_year, fire_protection, opening_protection, no_of_stories,
                central_reporting_fire_alarm_in, central_reporting_burglar_alarm_in, home_safe_in,
                fulltime_live_in_caretaker_in, backup_generator_in, residential_sprinkler_system_in,
                market_value_scheduled_items_coverage_in, bank_vaulted_jewelry_coverage_in, coins_coverage_in,
                collectibles_coverage_in, fine_arts_coverage_in, furs_coverage_in, guns_coverage_in,
                jewelry_coverage_in, miscellaneous_coverage_in, musical_instruments_coverage_in, silver_coverage_in,
                stamps_coverage_in, wearable_collectibles_coverage_in, wine_coverage_in,
                minimum_earned_premium_endorsement_in, minimum_earned_premium_endorsement_limit_pc,
                wardrobe_loss_prevention_in, companion_credit_homeowner_in, agreed_value_limitations_in,
                agreed_value_specified_class_limitations_in, agreed_value_specified_class_bank_vaulted_jewelry_limitations_in,
                agreed_value_specified_class_coins_limitations_in, agreed_value_specified_class_collectibles_limitations_in,
                agreed_value_specified_class_fine_arts_limitations_in, agreed_value_specified_class_furs_limitations_in,
                agreed_value_specified_class_guns_limitations_in, agreed_value_specified_class_worldwide_jewelry_limitations_in,
                agreed_value_specified_class_miscellaneous_limitations_in, agreed_value_specified_class_musicalInstruments_limitations_in,
                agreed_value_specified_class_silver_limitations_in, agreed_value_specified_class_stamps_limitations_in,
                agreed_value_specified_class_wearable_collectibles_limitations_in, agreed_value_specified_class_wine_limitations_in,
                agreed_value_specified_items_limitations_in, alarm_warranty_limitations_in, breakage_exclusion_limitations_in,
                terrorism_limitations_in, terrorism_limitations_amt, theft_mysterious_disappearance_exclusion_in,
                transit_limit_in, transit_limit_amt, hurricane_loss_exclusion_in, hurricane_loss_limitation_in,
                hurricane_loss_limitation_amt, outdoor_fine_art_hurricane_exclusion_in, terrorism_exclusion_in,
                deletion_of_cosmetic_marring_exclusion_in, earthquake_exclusion_in, earthquake_deductible_loss_limitations_in,
                earthquake_deductible_loss_limitations_limit, hotel_motel_exclusion_in, jewelry_off_premises_loss_limitation_in,
                spoilage_exclusion_in, change_in_terms_summary_in, change_in_terms_options, manuscript_in,
                coverage_deductible_in, coverage_deductible_amt, hurricane_deductible_in, hurricane_deductible_type,
                hurricane_deductible_amt, earthquake_deductible_in, earthquake_deductible_amt, wildfire_deductible_in,
                wildfire_deductible_type, wildfire_deductible_amt, wildfire_bark_mulch_within_ten_feet_of_any_structure_in,
                wildfire_combustible_deck_or_attached_structure_in, wildfire_combustible_wood_siding_in,
                wildfire_defensible_space_in, wildfire_distance_to_high_fuel_feet, wildfire_distance_to_moderate_fuel_feet,
                wildfire_distance_to_very_high_fuel_feet, wildfire_eaves_or_enclosed_eaves_in, wildfire_exteriorWildfireSprinklers_in,
                wildfire_firewood_or_combustibles_stored_against_home_in, wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in,
                wildfire_gutter_guards_in, wildfire_hazard_severity, wildfire_nearest_distance_to_perimeter,
                wildfire_no_of_occurrences_near, wildfire_no_of_occurrences, wildfire_permanently_installed_spray_system_in,
                wildfire_portable_fire_break_system_in, wildfire_speciality_ember_resistant_venting_in, wildfire_threat,
                wildfire_wood_shake_or_shingle_roof_in, couture_wearable_collectibles_class_in,
                source_system_sk, create_ts, update_ts, etl_audit_sk
            )
            VALUES (
                SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no,
                SOURCE.quote_collection_location_sk, SOURCE.quote_history_sk, SOURCE.unoccupied_more_than_three_months_in,
                SOURCE.valuable_article_losses_last3_years_ct, SOURCE.protection_class, SOURCE.terrain_cd,
                SOURCE.distance_to_coast, SOURCE.roof_geometry, SOURCE.roof_covering, SOURCE.roof_cover_deck,
                SOURCE.roof_deck_Attachment, SOURCE.roof_wall_Attachment, SOURCE.hail_resistant_rating,
                SOURCE.secondary_water_resistance, SOURCE.construction_type, SOURCE.built_year,
                SOURCE.fire_protection, SOURCE.opening_protection, SOURCE.no_of_stories,
                SOURCE.central_reporting_fire_alarm_in, SOURCE.central_reporting_burglar_alarm_in, SOURCE.home_safe_in,
                SOURCE.fulltime_live_in_caretaker_in, SOURCE.backup_generator_in, SOURCE.residential_sprinkler_system_in,
                SOURCE.market_value_scheduled_items_coverage_in, SOURCE.bank_vaulted_jewelry_coverage_in, SOURCE.coins_coverage_in,
                SOURCE.collectibles_coverage_in, SOURCE.fine_arts_coverage_in, SOURCE.furs_coverage_in, SOURCE.guns_coverage_in,
                SOURCE.jewelry_coverage_in, SOURCE.miscellaneous_coverage_in, SOURCE.musical_instruments_coverage_in, SOURCE.silver_coverage_in,
                SOURCE.stamps_coverage_in, SOURCE.wearable_collectibles_coverage_in, SOURCE.wine_coverage_in,
                SOURCE.minimum_earned_premium_endorsement_in, SOURCE.minimum_earned_premium_endorsement_limit_pc,
                SOURCE.wardrobe_loss_prevention_in, SOURCE.companion_credit_homeowner_in, SOURCE.agreed_value_limitations_in,
                SOURCE.agreed_value_specified_class_limitations_in, SOURCE.agreed_value_specified_class_bank_vaulted_jewelry_limitations_in,
                SOURCE.agreed_value_specified_class_coins_limitations_in, SOURCE.agreed_value_specified_class_collectibles_limitations_in,
                SOURCE.agreed_value_specified_class_fine_arts_limitations_in, SOURCE.agreed_value_specified_class_furs_limitations_in,
                SOURCE.agreed_value_specified_class_guns_limitations_in, SOURCE.agreed_value_specified_class_worldwide_jewelry_limitations_in,
                SOURCE.agreed_value_specified_class_miscellaneous_limitations_in, SOURCE.agreed_value_specified_class_musicalInstruments_limitations_in,
                SOURCE.agreed_value_specified_class_silver_limitations_in, SOURCE.agreed_value_specified_class_stamps_limitations_in,
                SOURCE.agreed_value_specified_class_wearable_collectibles_limitations_in, SOURCE.agreed_value_specified_class_wine_limitations_in,
                SOURCE.agreed_value_specified_items_limitations_in, SOURCE.alarm_warranty_limitations_in, SOURCE.breakage_exclusion_limitations_in,
                SOURCE.terrorism_limitations_in, SOURCE.terrorism_limitations_amt, SOURCE.theft_mysterious_disappearance_exclusion_in,
                SOURCE.transit_limit_in, SOURCE.transit_limit_amt, SOURCE.hurricane_loss_exclusion_in, SOURCE.hurricane_loss_limitation_in,
                SOURCE.hurricane_loss_limitation_amt, SOURCE.outdoor_fine_art_hurricane_exclusion_in, SOURCE.terrorism_exclusion_in,
                SOURCE.deletion_of_cosmetic_marring_exclusion_in, SOURCE.earthquake_exclusion_in, SOURCE.earthquake_deductible_loss_limitations_in,
                SOURCE.earthquake_deductible_loss_limitations_limit, SOURCE.hotel_motel_exclusion_in, SOURCE.jewelry_off_premises_loss_limitation_in,
                SOURCE.spoilage_exclusion_in, SOURCE.change_in_terms_summary_in, SOURCE.change_in_terms_options, SOURCE.manuscript_in,
                SOURCE.coverage_deductible_in, SOURCE.coverage_deductible_amt, SOURCE.hurricane_deductible_in, SOURCE.hurricane_deductible_type,
                SOURCE.hurricane_deductible_amt, SOURCE.earthquake_deductible_in, SOURCE.earthquake_deductible_amt, SOURCE.wildfire_deductible_in,
                SOURCE.wildfire_deductible_type, SOURCE.wildfire_deductible_amt, SOURCE.wildfire_bark_mulch_within_ten_feet_of_any_structure_in,
                SOURCE.wildfire_combustible_deck_or_attached_structure_in, SOURCE.wildfire_combustible_wood_siding_in,
                SOURCE.wildfire_defensible_space_in, SOURCE.wildfire_distance_to_high_fuel_feet, SOURCE.wildfire_distance_to_moderate_fuel_feet,
                SOURCE.wildfire_distance_to_very_high_fuel_feet, SOURCE.wildfire_eaves_or_enclosed_eaves_in, SOURCE.wildfire_exteriorWildfireSprinklers_in,
                SOURCE.wildfire_firewood_or_combustibles_stored_against_home_in, SOURCE.wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in,
                SOURCE.wildfire_gutter_guards_in, SOURCE.wildfire_hazard_severity, SOURCE.wildfire_nearest_distance_to_perimeter,
                SOURCE.wildfire_no_of_occurrences_near, SOURCE.wildfire_no_of_occurrences, SOURCE.wildfire_permanently_installed_spray_system_in,
                SOURCE.wildfire_portable_fire_break_system_in, SOURCE.wildfire_speciality_ember_resistant_venting_in, SOURCE.wildfire_threat,
                SOURCE.wildfire_wood_shake_or_shingle_roof_in, SOURCE.couture_wearable_collectibles_class_in,
                SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk
        );

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM [edw_temp].[tquote_collection_coverage_wip_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tquote_collection_coverage_wip_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END

GO