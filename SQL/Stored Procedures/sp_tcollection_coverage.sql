-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Additional Coverage 
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 08/14/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 10/09/23		Architha Gudimalla				2. Made changes after sandeep renamed the coll tables
-- 10/09/23		Sandeep Gundreddy				3. renamed temp table name
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcollection_coverage]
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
		DROP TABLE IF EXISTS [edw_temp].[tcollection_coverage_temp1];

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
				pd.[Name] in ('Collections'--,'Homeowners'
                )
				AND pdo.ObjectType='Collection'
				AND pd.ProductLine='PersonalLines' --20230717 added
		) AS ColumnsToPivot_temp

		-- Remove last comma
		SET @ColumnsToPivot = LEFT(@ColumnsToPivot, LEN(@ColumnsToPivot) - 1);
	
		DECLARE @sql NVARCHAR(max)
		SET @sql ='SELECT Id, PolicyNumber, EffectiveDate, IssuedDate, ExpirationDate, transaction_dt, PolicyChangeNumber
			,collection_location_sk
			,policy_history_sk
			,UnoccupiedMoreThanThreeMonths,NumberOfLossesLastThreeYears,ProtectionClass,Terrain,DistanceToCoast,RoofGeometry,RoofCovering,RoofCoverDeck,RoofDeckAttachment,RoofWallAttachment,HailResistantRating,SecondaryWaterResistance,ConstructionType,YearBuilt,FireProtection,OpeningProtection,NumberOfStories,CentralReportingFireAlarm,CentralReportingBurglarAlarm,HomeSafe,FulltimeLiveInCaretaker,BackupGenerator,ResidentialSprinklerSystem,MarketValueScheduledItems,MarketScheduledClassBankVaultedJewelry,MarketScheduledClassCoins,MarketScheduledClassCollectibles,MarketScheduledClassFineArts,MarketScheduledClassFurs,MarketScheduledClassGuns,MarketScheduledClassWorldwideJewelry,MarketScheduledClassMiscellaneous,MarketScheduledClassMusicalInstruments,MarketScheduledClassSilver,MarketScheduledClassStamps,MarketScheduledClassWearableCollectibles,MarketScheduledClassWine,MinimumEarnedPremiumEndorsement,TRY_CONVERT(float, MinimumEarnedPremiumEndorsementLimit) as MinimumEarnedPremiumEndorsementLimit,WardrobeLossPrevention,CompanionCreditHomeowner,AgreedValue,AgreedValueSpecifiedClass,AgreedValueSpecifiedClassBankVaultedJewelry,AgreedValueSpecifiedClassCoins,AgreedValueSpecifiedClassCollectibles,AgreedValueSpecifiedClassFineArts,AgreedValueSpecifiedClassFurs,AgreedValueSpecifiedClassGuns,AgreedValueSpecifiedClassWorldwideJewelry,AgreedValueSpecifiedClassMiscellaneous,AgreedValueSpecifiedClassMusicalInstruments,AgreedValueSpecifiedClassSilver,AgreedValueSpecifiedClassStamps,AgreedValueSpecifiedClassWearableCollectibles,AgreedValueSpecifiedClassWine,AgreedValueSpecifiedItems,AlarmWarranty,BreakageExclusion,TerrorismLimitation,TerrorismLimitationAmount,TheftMysteriousDisappearanceExclusion,TransitLimit,TransitLimitAmount,HurricaneLossExclusion,HurricaneLossLimitation,HurricaneLossLimitationAmount,OutdoorFineArtHurricaneExclusion,TerrorismExclusion,DeletionofCosmeticMarringExclusion,EarthquakeExclusion,EarthquakeDeductibleLossLimitation,EarthquakeDeductibleLossLimitationLimit,HotelMotelExclusion,JewelryOffPremisesLossLimitation,SpoilageExclusion,ChangeinTermsSummary,ChangeinTermsOptions,Manuscript,CoverageDeductible,CoverageDeductibleAmount,HurricaneDeductible,HurricaneDeductibleType,HurricaneDeductibleLimit,EarthquakeDeductible,EarthquakeDeductibleAmount,WildfireDeductible,WildfireDeductibleType,WildfireDeductibleAmount,WildfireBarkMulchWithinTenFeetofAnyStructure,WildfireCombustibleDeckOrAttachedStructure,WildfireCombustibleWoodSiding,WildfireDefensibleSpace,WildfireDistanceToHighFuelFeet,WildfireDistanceToModerateFuelFeet,WildfireDistanceToVeryHighFuelFeet,WildfireEavesorEnclosedEaves,WildfireExteriorWildfireSprinklers,WildfireFireWoodOrCombustiblesStoredAgainstHome,WildfireFlammableVegetationWithinTenFeetofAnyStructure,WildfireGutterGuards,WildfireHazardSeverity,WildfireNearestDistanceToPerimeter,WildfireNumberOfOccurrencesNear,WildfireNumberOfOccurrences,WildfirePermanentlyInstalledSpraySystem,WildfirePortableFireBreakSystem,WildfireSpecialityEmberResistantVenting,WildfireThreat,WildfireWoodShakeOrShingleRoof,CoutureAndWearableCollectiblesClassCouture
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			INTO [edw_temp].[tcollection_coverage_temp1]
			FROM
			(
				SELECT acct.Id, acc.PolicyNumber, acc.EffectiveDate, acc.IssuedDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, acc.PolicyChangeNumber
					,loc.[collection_location_sk] as [collection_location_sk]
					,his.[policy_history_sk] as [policy_history_sk]
					,accto.Field, accto.[Value]
					,acct.ObjectType
					,acc.CreatedDate, acc.UpdatedDate
					,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
						  Else 4 --(Metal)
					 end as [source_system_sk] --20230717 added
				FROM
					(SELECT
						acct.*
					FROM [edw_stage].[AccountTransaction] acct
					WHERE
						acct.State =''ISSUED'' --- Review BOUND transactions
						AND acct.IssuedDate > @last_source_extract_ts --20230717 added
					) acc
					INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
					LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
					LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
					LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
					LEFT JOIN [edw_core].[tcollection_location] loc on loc.policy_no = acc.PolicyNumber
					LEFT JOIN [edw_core].[tpolicy_history] his on his.policy_no = acc.PolicyNumber and his.effective_dt = acc.EffectiveDate and his.transaction_seq_no = acc.policychangenumber
				WHERE
					p.Name=''Collections''
					and acct.ObjectType = ''Collection''
					and p.ProductLine=''PersonalLines'' --20230717 added
			) AS t
			PIVOT 
			(
				max(Value) FOR Field IN (UnoccupiedMoreThanThreeMonths,NumberOfLossesLastThreeYears,ProtectionClass,Terrain,DistanceToCoast,RoofGeometry,RoofCovering,RoofCoverDeck,RoofDeckAttachment,RoofWallAttachment,HailResistantRating,SecondaryWaterResistance,ConstructionType,YearBuilt,FireProtection,OpeningProtection,NumberOfStories,CentralReportingFireAlarm,CentralReportingBurglarAlarm,HomeSafe,FulltimeLiveInCaretaker,BackupGenerator,ResidentialSprinklerSystem,MarketValueScheduledItems,MarketScheduledClassBankVaultedJewelry,MarketScheduledClassCoins,MarketScheduledClassCollectibles,MarketScheduledClassFineArts,MarketScheduledClassFurs,MarketScheduledClassGuns,MarketScheduledClassWorldwideJewelry,MarketScheduledClassMiscellaneous,MarketScheduledClassMusicalInstruments,MarketScheduledClassSilver,MarketScheduledClassStamps,MarketScheduledClassWearableCollectibles,MarketScheduledClassWine,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,WardrobeLossPrevention,CompanionCreditHomeowner,AgreedValue,AgreedValueSpecifiedClass,AgreedValueSpecifiedClassBankVaultedJewelry,AgreedValueSpecifiedClassCoins,AgreedValueSpecifiedClassCollectibles,AgreedValueSpecifiedClassFineArts,AgreedValueSpecifiedClassFurs,AgreedValueSpecifiedClassGuns,AgreedValueSpecifiedClassWorldwideJewelry,AgreedValueSpecifiedClassMiscellaneous,AgreedValueSpecifiedClassMusicalInstruments,AgreedValueSpecifiedClassSilver,AgreedValueSpecifiedClassStamps,AgreedValueSpecifiedClassWearableCollectibles,AgreedValueSpecifiedClassWine,AgreedValueSpecifiedItems,AlarmWarranty,BreakageExclusion,TerrorismLimitation,TerrorismLimitationAmount,TheftMysteriousDisappearanceExclusion,TransitLimit,TransitLimitAmount,HurricaneLossExclusion,HurricaneLossLimitation,HurricaneLossLimitationAmount,OutdoorFineArtHurricaneExclusion,TerrorismExclusion,DeletionofCosmeticMarringExclusion,EarthquakeExclusion,EarthquakeDeductibleLossLimitation,EarthquakeDeductibleLossLimitationLimit,HotelMotelExclusion,JewelryOffPremisesLossLimitation,SpoilageExclusion,ChangeinTermsSummary,ChangeinTermsOptions,Manuscript,CoverageDeductible,CoverageDeductibleAmount,HurricaneDeductible,HurricaneDeductibleType,HurricaneDeductibleLimit,EarthquakeDeductible,EarthquakeDeductibleAmount,WildfireDeductible,WildfireDeductibleType,WildfireDeductibleAmount,WildfireBarkMulchWithinTenFeetofAnyStructure,WildfireCombustibleDeckOrAttachedStructure,WildfireCombustibleWoodSiding,WildfireDefensibleSpace,WildfireDistanceToHighFuelFeet,WildfireDistanceToModerateFuelFeet,WildfireDistanceToVeryHighFuelFeet,WildfireEavesorEnclosedEaves,WildfireExteriorWildfireSprinklers,WildfireFireWoodOrCombustiblesStoredAgainstHome,WildfireFlammableVegetationWithinTenFeetofAnyStructure,WildfireGutterGuards,WildfireHazardSeverity,WildfireNearestDistanceToPerimeter,WildfireNumberOfOccurrencesNear,WildfireNumberOfOccurrences,WildfirePermanentlyInstalledSpraySystem,WildfirePortableFireBreakSystem,WildfireSpecialityEmberResistantVenting,WildfireThreat,WildfireWoodShakeOrShingleRoof,CoutureAndWearableCollectiblesClassCouture)
			) AS pivottable
			'

		--EXECUTE sp_executesql @sql
		EXECUTE sp_executesql @sql, N'@last_source_extract_ts datetime2(7)', @last_source_extract_ts = @last_source_extract_ts

		-- Start Insert process
		INSERT INTO [edw_core].[tcollection_coverage] (
			[policy_no]
           ,[effective_dt]
           ,[transaction_effective_dt]
           ,[expiration_dt]
           ,[transaction_dt]
           ,[transaction_seq_no]
           ,[collection_location_sk]
           ,[policy_history_sk]
           ,[unoccupied_more_than_three_months_in]
           ,[valuable_article_losses_last3_years_ct]
           ,[protection_class]
           ,[terrain_cd]
           ,[distance_to_coast]
           ,[roof_geometry]
           ,[roof_covering]
           ,[roof_cover_deck]
           ,[roof_deck_Attachment]
           ,[roof_wall_Attachment]
           ,[hail_resistant_rating]
           ,[secondary_water_resistance]
           ,[construction_type]
           ,[built_year]
           ,[fire_protection]
           ,[opening_protection]
           ,[no_of_stories]
           ,[central_reporting_fire_alarm_in]
           ,[central_reporting_burglar_alarm_in]
           ,[home_safe_in]
           ,[fulltime_live_in_caretaker_in]
           ,[backup_generator_in]
           ,[residential_sprinkler_system_in]
           ,[market_value_scheduled_items_coverage_in]
           ,[bank_vaulted_jewelry_coverage_in]
           ,[coins_coverage_in]
           ,[collectibles_coverage_in]
           ,[fine_arts_coverage_in]
           ,[furs_coverage_in]
           ,[guns_coverage_in]
           ,[jewelry_coverage_in]
           ,[miscellaneous_coverage_in]
           ,[musical_instruments_coverage_in]
           ,[silver_coverage_in]
           ,[stamps_coverage_in]
           ,[wearable_collectibles_coverage_in]
           ,[wine_coverage_in]
           ,[minimum_earned_premium_endorsement_in]
           ,[minimum_earned_premium_endorsement_limit_pc]
           ,[wardrobe_loss_prevention_in]
           ,[companion_credit_homeowner_in]
           ,[agreed_value_limitations_in]
           ,[agreed_value_specified_class_limitations_in]
           ,[agreed_value_specified_class_bank_vaulted_jewelry_limitations_in]
           ,[agreed_value_specified_class_coins_limitations_in]
           ,[agreed_value_specified_class_collectibles_limitations_in]
           ,[agreed_value_specified_class_fine_arts_limitations_in]
           ,[agreed_value_specified_class_furs_limitations_in]
           ,[agreed_value_specified_class_guns_limitations_in]
           ,[agreed_value_specified_class_worldwide_jewelry_limitations_in]
           ,[agreed_value_specified_class_miscellaneous_limitations_in]
           ,[agreed_value_specified_class_musicalInstruments_limitations_in]
           ,[agreed_value_specified_class_silver_limitations_in]
           ,[agreed_value_specified_class_stamps_limitations_in]
           ,[agreed_value_specified_class_wearable_collectibles_limitations_in]
           ,[agreed_value_specified_class_wine_limitations_in]
           ,[agreed_value_specified_items_limitations_in]
           ,[alarm_warranty_limitations_in]
           ,[breakage_exclusion_limitations_in]
           ,[terrorism_limitations_in]
           ,[Terrorism_limitations_amt]
           ,[theft_mysterious_disappearance_exclusion_in]
           ,[transit_limit_in]
           ,[transit_limit_amt]
           ,[hurricane_loss_exclusion_in]
           ,[hurricane_loss_limitation_in]
           ,[hurricane_loss_limitation_amt]
           ,[outdoor_fine_art_hurricane_exclusion_in]
           ,[terrorism_exclusion_in]
           ,[deletion_of_cosmetic_marring_exclusion_in]
           ,[earthquake_exclusion_in]
           ,[earthquake_deductible_loss_limitations_in]
           ,[earthquake_deductible_loss_limitations_limit]
           ,[hotel_motel_exclusion_in]
           ,[jewelry_off_premises_loss_limitation_in]
           ,[spoilage_exclusion_in]
           ,[change_in_terms_summary_in]
           ,[change_in_terms_options]
           ,[manuscript_in]
           ,[coverage_deductible_in]
           ,[coverage_deductible_amt]
           ,[hurricane_deductible_in]
           ,[hurricane_deductible_type]
           ,[hurricane_deductible_amt]
           ,[earthquake_deductible_in]
           ,[earthquake_deductible_amt]
           ,[wildfire_deductible_in]
           ,[wildfire_deductible_type]
           ,[wildfire_deductible_amt]
           ,[wildfire_bark_mulch_within_ten_feet_of_any_structure_in]
           ,[wildfire_combustible_deck_or_attached_structure_in]
           ,[wildfire_combustible_wood_siding_in]
           ,[wildfire_defensible_space_in]
           ,[wildfire_distance_to_high_fuel_feet]
           ,[wildfire_distance_to_moderate_fuel_feet]
           ,[wildfire_distance_to_very_high_fuel_feet]
           ,[wildfire_eaves_or_enclosed_eaves_in]
           ,[wildfire_exteriorWildfireSprinklers_in]
           ,[wildfire_firewood_or_combustibles_stored_against_home_in]
           ,[wildfire_flammable_vegetation_within_ten_feet_of_any_structure_in]
           ,[wildfire_gutter_guards_in]
           ,[wildfire_hazard_severity]
           ,[wildfire_nearest_distance_to_perimeter]
           ,[wildfire_no_of_occurrences_near]
           ,[wildfire_no_of_occurrences]
           ,[wildfire_permanently_installed_spray_system_in]
           ,[wildfire_portable_fire_break_system_in]
           ,[wildfire_speciality_ember_resistant_venting_in]
           ,[wildfire_threat]
           ,[wildfire_wood_shake_or_shingle_roof_in]
		   ,[couture_wearable_collectibles_class_in]
           ,[source_system_sk]
           ,[create_ts]
           ,[update_ts]
           ,[etl_audit_sk]
			)
		SELECT 
			[PolicyNumber],[EffectiveDate],[IssuedDate],[ExpirationDate],[transaction_dt],[PolicyChangeNumber],
            [collection_location_sk],[policy_history_sk],[UnoccupiedMoreThanThreeMonths],[NumberOfLossesLastThreeYears],[ProtectionClass],
            [Terrain],[DistanceToCoast],[RoofGeometry],[RoofCovering],[RoofCoverDeck],[RoofDeckAttachment],[RoofWallAttachment],[HailResistantRating],
            [SecondaryWaterResistance],[ConstructionType],[YearBuilt],[FireProtection],[OpeningProtection],[NumberOfStories],[CentralReportingFireAlarm],
            [CentralReportingBurglarAlarm],[HomeSafe],[FulltimeLiveInCaretaker],[BackupGenerator],[ResidentialSprinklerSystem],[MarketValueScheduledItems],
            [MarketScheduledClassBankVaultedJewelry],[MarketScheduledClassCoins],[MarketScheduledClassCollectibles],[MarketScheduledClassFineArts],
            [MarketScheduledClassFurs],[MarketScheduledClassGuns],[MarketScheduledClassWorldwideJewelry],[MarketScheduledClassMiscellaneous],
            [MarketScheduledClassMusicalInstruments],[MarketScheduledClassSilver],[MarketScheduledClassStamps],[MarketScheduledClassWearableCollectibles],
            [MarketScheduledClassWine],[MinimumEarnedPremiumEndorsement],[MinimumEarnedPremiumEndorsementLimit],[WardrobeLossPrevention],[CompanionCreditHomeowner],
            [AgreedValue],[AgreedValueSpecifiedClass],[AgreedValueSpecifiedClassBankVaultedJewelry],[AgreedValueSpecifiedClassCoins],
            [AgreedValueSpecifiedClassCollectibles],[AgreedValueSpecifiedClassFineArts],[AgreedValueSpecifiedClassFurs],[AgreedValueSpecifiedClassGuns],
            [AgreedValueSpecifiedClassWorldwideJewelry],[AgreedValueSpecifiedClassMiscellaneous],[AgreedValueSpecifiedClassMusicalInstruments],
            [AgreedValueSpecifiedClassSilver],[AgreedValueSpecifiedClassStamps],[AgreedValueSpecifiedClassWearableCollectibles],[AgreedValueSpecifiedClassWine],
            [AgreedValueSpecifiedItems],[AlarmWarranty],[BreakageExclusion],[TerrorismLimitation],[TerrorismLimitationAmount],[TheftMysteriousDisappearanceExclusion],
            [TransitLimit],[TransitLimitAmount],[HurricaneLossExclusion],[HurricaneLossLimitation],[HurricaneLossLimitationAmount],[OutdoorFineArtHurricaneExclusion],
            [TerrorismExclusion],[DeletionofCosmeticMarringExclusion],[EarthquakeExclusion],[EarthquakeDeductibleLossLimitation],
            [EarthquakeDeductibleLossLimitationLimit],[HotelMotelExclusion],[JewelryOffPremisesLossLimitation],[SpoilageExclusion],[ChangeinTermsSummary],
            [ChangeinTermsOptions],[Manuscript],[CoverageDeductible],[CoverageDeductibleAmount],[HurricaneDeductible],[HurricaneDeductibleType],
            [HurricaneDeductibleLimit],[EarthquakeDeductible],[EarthquakeDeductibleAmount],[WildfireDeductible],[WildfireDeductibleType],[WildfireDeductibleAmount],
            [WildfireBarkMulchWithinTenFeetofAnyStructure],[WildfireCombustibleDeckOrAttachedStructure],[WildfireCombustibleWoodSiding],[WildfireDefensibleSpace],
            [WildfireDistanceToHighFuelFeet],[WildfireDistanceToModerateFuelFeet],[WildfireDistanceToVeryHighFuelFeet],[WildfireEavesorEnclosedEaves],
            [WildfireExteriorWildfireSprinklers],[WildfireFireWoodOrCombustiblesStoredAgainstHome],[WildfireFlammableVegetationWithinTenFeetofAnyStructure],
            [WildfireGutterGuards],[WildfireHazardSeverity],[WildfireNearestDistanceToPerimeter],[WildfireNumberOfOccurrencesNear],[WildfireNumberOfOccurrences],
            [WildfirePermanentlyInstalledSpraySystem],[WildfirePortableFireBreakSystem],[WildfireSpecialityEmberResistantVenting],[WildfireThreat],
            [WildfireWoodShakeOrShingleRoof],[CoutureAndWearableCollectiblesClassCouture],[source_system_sk],getdate(),getdate(), @etl_audit_sk
		FROM
			[edw_temp].[tcollection_coverage_temp1] 

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.[tcollection_coverage_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tcollection_coverage_temp1];
		
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

