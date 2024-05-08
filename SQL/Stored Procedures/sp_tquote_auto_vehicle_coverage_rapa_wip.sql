SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================================================================================
-- Author:		Hernando Gonzalez
-- Create Date: 2024-05-07
-- Description: This stored procedure insert and update info related to tquote_auto_vehicle_coverage_rapa_wip.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 07/05/24		Hernando Gonzalez			1. Initial Version
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_vehicle_coverage_rapa_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_vehicle_coverage_rapa_wip_temp1];

		SELECT 
			CreatedDate, quote_no, effective_dt, vehicle_no, expiration_dt, 0 as transaction_seq_no, quote_history_sk, quote_auto_vehicle_sk, quote_auto_vehicle_coverage_sk
            ,RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, 
			RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, 
			RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, 
			RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, 
			RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, 
			RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, 
			RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, 
			RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, 
			RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, 
			RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, 
			RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, 
			RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, 
			RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			,vehicle_unique_id, source_system_sk
        INTO [edw_temp].[tquote_auto_vehicle_coverage_rapa_wip_temp1]
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, qav.[vehicle_no] as vehicle_no, acco.[UniqueId] as vehicle_unique_id,
                    acc.ExpirationDate as expiration_dt, acc.[Number] as transaction_seq_no,
                    qh.quote_history_sk, qav.quote_auto_vehicle_sk, qavc.quote_auto_vehicle_coverage_sk, 
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
                INNER JOIN [edw_core].[tquote_auto_vehicle] AS qav
                    ON qav.quote_no = acc.PolicyNumber
					AND qav.effective_dt = acc.EffectiveDate
                    AND qav.vehicle_no = acco.[Index]
				INNER JOIN [edw_core].[tquote_auto_vehicle_coverage] AS qavc
					ON qavc.quote_no = acc.PolicyNumber
                    AND qavc.effective_dt = CAST(acc.EffectiveDate AS DATE)
                    AND qavc.transaction_seq_no = acc.[Number]
					AND qavc.vehicle_no = qav.vehicle_no
				LEFT JOIN [edw_core].[tquote_history] AS qh 
                    ON qh.quote_no = acc.PolicyNumber
                    AND qh.effective_dt = acc.EffectiveDate
                    AND qh.transaction_seq_no = acc.[Number]
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Symbols', 'Symbols - ISO')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, 
					RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, 
					RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, 
					RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, 
					RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, 
					RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, 
					RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, 
					RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, 
					RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, 
					RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, 
					RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, 
					RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, 
					RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
                )
			) pivottable

		-- Start Insert process
		MERGE INTO [edw_core].[tquote_auto_vehicle_coverage_rapa] AS target
		USING [edw_temp].[tquote_auto_vehicle_coverage_rapa_wip_temp1] AS source
			ON target.quote_no = source.quote_no
			AND target.effective_dt = source.effective_dt
			AND target.vehicle_no = source.vehicle_no
			AND target.transaction_seq_no = source.transaction_seq_no
		WHEN MATCHED THEN
			UPDATE SET 
				target.expiration_dt = source.expiration_dt,
				target.quote_history_sk = source.quote_history_sk,
				target.quote_auto_vehicle_sk = source.quote_auto_vehicle_sk,
				target.quote_auto_vehicle_coverage_sk = source.quote_auto_vehicle_coverage_sk,
				target.bodily_injury_char1_relativity = source.RAPABodilyInjuryIndicatedSymbolRelativityChar1,
				target.property_damage_char1_relativity = source.RAPAPropertyDamageIndicatedSymbolRelativityChar1,
				target.medical_payments_char1_relativity = source.RAPAMedicalPaymentsIndicatedSymbolRelativityChar1,
				target.personal_injury_protection_char1_relativity = source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1,
				target.collision_char1_relativity = source.RAPACollisionIndicatedSymbolRelativityChar1,
				target.comprehensive_char1_relativity = source.RAPAComprehensiveIndicatedSymbolRelativityChar1,
				target.single_limit_char1_relativity = source.RAPASingleLimitIndicatedSymbolRelativityChar1,
				target.bodily_injury_char2_relativity = source.RAPABodilyInjuryIndicatedSymbolRelativityChar2,
				target.property_damage_char2_relativity = source.RAPAPropertyDamageIndicatedSymbolRelativityChar2,
				target.medical_payments_char2_relativity = source.RAPAMedicalPaymentsIndicatedSymbolRelativityChar2,
				target.personal_injury_protection_char2_relativity = source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2,
				target.collision_char2_relativity = source.RAPACollisionIndicatedSymbolRelativityChar2,
				target.comprehensive_char2_relativity = source.RAPAComprehensiveIndicatedSymbolRelativityChar2,
				target.single_limit_char2_relativity = source.RAPASingleLimitIndicatedSymbolRelativityChar2,
				target.bodily_injury_indicated_symbol = source.RAPABodilyInjuryIndicatedSymbol,
				target.property_damage_indicated_symbol = source.RAPAPropertyDamageIndicatedSymbol,
				target.medical_payments_indicated_symbol = source.RAPAMedicalPaymentsIndicatedSymbol,
				target.personal_injury_protection_indicated_symbol = source.RAPAPersonalInjuryProtectionIndicatedSymbol,
				target.collision_indicated_symbol = source.RAPACollisionIndicatedSymbol,
				target.comprehensive_indicated_symbol = source.RAPAComprehensiveIndicatedSymbol,
				target.single_limit_indicated_symbol = source.RAPASingleLimitIndicatedSymbol,
				target.bodily_injury_relativity = source.RAPABodilyInjuryIndicatedSymbolRelativity,
				target.property_damage_relativity = source.RAPAPropertyDamageIndicatedSymbolRelativity,
				target.medical_payments_relativity = source.RAPAMedicalPaymentsIndicatedSymbolRelativity,
				target.personal_injury_protection_relativity = source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativity,
				target.collision_relativity = source.RAPACollisionIndicatedSymbolRelativity,
				target.comprehensive_relativity = source.RAPAComprehensiveIndicatedSymbolRelativity,
				target.single_limit_relativity = source.RAPASingleLimitIndicatedSymbolRelativity,
				target.comprehensive_non_glass_relativity_char1 = source.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1,
				target.comprehensive_non_glass_relativity_char2 = source.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2,
				target.comprehensive_non_glass_indicated_symbol = source.RAPAComprehensiveNonGlassIndicatedSymbol,
				target.comprehensive_non_glass_symbol_relativity = source.RAPAComprehensiveNonGlassIndicatedSymbolRelativity,
				target.bodily_injury_rating_symbol_relativity = source.RAPABodilyInjuryRatingSymbolRelativity,
				target.bodily_injury_symbol = source.RAPASymbolBI,
				target.property_damage_rating_symbol_relativity = source.RAPAPropertyDamageRatingSymbolRelativity,
				target.property_damage_symbol = source.RAPASymbolPD,
				target.medical_payments_rating_symbol_relativity = source.RAPAMedicalPaymentsRatingSymbolRelativity,
				target.medical_payments_symbol = source.RAPASymbolMP,
				target.personal_injury_protection_rating_symbol_relativity = source.RAPAPersonalInjuryProtectionRatingSymbolRelativity,
				target.personal_injury_protection_symbol = source.RAPASymbolNF,
				target.collision_rating_symbol_relativity = source.RAPACollisionRatingSymbolRelativity,
				target.collision_symbol = source.RAPASymbolCL,
				target.comprehensive_rating_symbol_relativity = source.RAPAComprehensiveRatingSymbolRelativity,
				target.comprehensive_symbol = source.RAPASymbolCP,
				target.single_limit_rating_symbol_relativity = source.RAPASingleLimitRatingSymbolRelativity,
				target.single_limit_symbol = source.RAPASymbolSL,
				target.comprehensive_non_glass_rating_symbol_relativity = source.RAPAComprehensiveNonGlassRatingSymbolRelativity,
				target.comprehensive_non_glass_symbol = source.RAPASymbolCN,
				target.bodily_injury_symbol_capping_in = source.RAPASymbolCappingIndicatorBI,
				target.property_damage_symbol_capping_in = source.RAPASymbolCappingIndicatorPD,
				target.medical_payments_symbol_capping_in = source.RAPASymbolCappingIndicatorMP,
				target.personal_injury_protection_symbol_capping_in = source.RAPASymbolCappingIndicatorNF,
				target.collision_symbol_capping_in = source.RAPASymbolCappingIndicatorCL,
				target.comprehensive_symbol_capping_in = source.RAPASymbolCappingIndicatorCP,
				target.single_limit_symbol_capping_in = source.RAPASymbolCappingIndicatorSL,
				target.comprehensive_non_glass_symbol_capping_in = source.RAPASymbolCappingIndicatorCN,
				target.vehicle_unique_id = source.vehicle_unique_id,
				target.source_system_sk = source.source_system_sk,
				target.update_ts = GETDATE(),
				target.etl_audit_sk = @etl_audit_sk
		WHEN NOT MATCHED THEN
			INSERT (
				quote_no,
				effective_dt,
				vehicle_no,
				expiration_dt,
				transaction_seq_no,
				quote_history_sk,
				quote_auto_vehicle_sk,
				quote_auto_vehicle_coverage_sk,
				bodily_injury_char1_relativity,
				property_damage_char1_relativity,
				medical_payments_char1_relativity,
				personal_injury_protection_char1_relativity,
				collision_char1_relativity,
				comprehensive_char1_relativity,
				single_limit_char1_relativity,
				bodily_injury_char2_relativity,
				property_damage_char2_relativity,
				medical_payments_char2_relativity,
				personal_injury_protection_char2_relativity,
				collision_char2_relativity,
				comprehensive_char2_relativity,
				single_limit_char2_relativity,
				bodily_injury_indicated_symbol,
				property_damage_indicated_symbol,
				medical_payments_indicated_symbol,
				personal_injury_protection_indicated_symbol,
				collision_indicated_symbol,
				comprehensive_indicated_symbol,
				single_limit_indicated_symbol,
				bodily_injury_relativity,
				property_damage_relativity,
				medical_payments_relativity,
				personal_injury_protection_relativity,
				collision_relativity,
				comprehensive_relativity,
				single_limit_relativity,
				comprehensive_non_glass_relativity_char1,
				comprehensive_non_glass_relativity_char2,
				comprehensive_non_glass_indicated_symbol,
				comprehensive_non_glass_symbol_relativity,
				bodily_injury_rating_symbol_relativity,
				bodily_injury_symbol,
				property_damage_rating_symbol_relativity,
				property_damage_symbol,
				medical_payments_rating_symbol_relativity,
				medical_payments_symbol,
				personal_injury_protection_rating_symbol_relativity,
				personal_injury_protection_symbol,
				collision_rating_symbol_relativity,
				collision_symbol,
				comprehensive_rating_symbol_relativity,
				comprehensive_symbol,
				single_limit_rating_symbol_relativity,
				single_limit_symbol,
				comprehensive_non_glass_rating_symbol_relativity,
				comprehensive_non_glass_symbol,
				bodily_injury_symbol_capping_in,
				property_damage_symbol_capping_in,
				medical_payments_symbol_capping_in,
				personal_injury_protection_symbol_capping_in,
				collision_symbol_capping_in,
				comprehensive_symbol_capping_in,
				single_limit_symbol_capping_in,
				comprehensive_non_glass_symbol_capping_in,
				vehicle_unique_id,
				source_system_sk,
				create_ts,
				update_ts,
				etl_audit_sk
			)
			VALUES (
				source.quote_no,
				source.effective_dt,
				source.vehicle_no,
				source.expiration_dt,
				source.transaction_seq_no,
				source.quote_history_sk,
				source.quote_auto_vehicle_sk,
				source.quote_auto_vehicle_coverage_sk,
				source.RAPABodilyInjuryIndicatedSymbolRelativityChar1,
				source.RAPAPropertyDamageIndicatedSymbolRelativityChar1,
				source.RAPAMedicalPaymentsIndicatedSymbolRelativityChar1,
				source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1,
				source.RAPACollisionIndicatedSymbolRelativityChar1,
				source.RAPAComprehensiveIndicatedSymbolRelativityChar1,
				source.RAPASingleLimitIndicatedSymbolRelativityChar1,
				source.RAPABodilyInjuryIndicatedSymbolRelativityChar2,
				source.RAPAPropertyDamageIndicatedSymbolRelativityChar2,
				source.RAPAMedicalPaymentsIndicatedSymbolRelativityChar2,
				source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2,
				source.RAPACollisionIndicatedSymbolRelativityChar2,
				source.RAPAComprehensiveIndicatedSymbolRelativityChar2,
				source.RAPASingleLimitIndicatedSymbolRelativityChar2,
				source.RAPABodilyInjuryIndicatedSymbol,
				source.RAPAPropertyDamageIndicatedSymbol,
				source.RAPAMedicalPaymentsIndicatedSymbol,
				source.RAPAPersonalInjuryProtectionIndicatedSymbol,
				source.RAPACollisionIndicatedSymbol,
				source.RAPAComprehensiveIndicatedSymbol,
				source.RAPASingleLimitIndicatedSymbol,
				source.RAPABodilyInjuryIndicatedSymbolRelativity,
				source.RAPAPropertyDamageIndicatedSymbolRelativity,
				source.RAPAMedicalPaymentsIndicatedSymbolRelativity,
				source.RAPAPersonalInjuryProtectionIndicatedSymbolRelativity,
				source.RAPACollisionIndicatedSymbolRelativity,
				source.RAPAComprehensiveIndicatedSymbolRelativity,
				source.RAPASingleLimitIndicatedSymbolRelativity,
				source.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1,
				source.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2,
				source.RAPAComprehensiveNonGlassIndicatedSymbol,
				source.RAPAComprehensiveNonGlassIndicatedSymbolRelativity,
				source.RAPABodilyInjuryRatingSymbolRelativity,
				source.RAPASymbolBI,
				source.RAPAPropertyDamageRatingSymbolRelativity,
				source.RAPASymbolPD,
				source.RAPAMedicalPaymentsRatingSymbolRelativity,
				source.RAPASymbolMP,
				source.RAPAPersonalInjuryProtectionRatingSymbolRelativity,
				source.RAPASymbolNF,
				source.RAPACollisionRatingSymbolRelativity,
				source.RAPASymbolCL,
				source.RAPAComprehensiveRatingSymbolRelativity,
				source.RAPASymbolCP,
				source.RAPASingleLimitRatingSymbolRelativity,
				source.RAPASymbolSL,
				source.RAPAComprehensiveNonGlassRatingSymbolRelativity,
				source.RAPASymbolCN,
				source.RAPASymbolCappingIndicatorBI,
				source.RAPASymbolCappingIndicatorPD,
				source.RAPASymbolCappingIndicatorMP,
				source.RAPASymbolCappingIndicatorNF,
				source.RAPASymbolCappingIndicatorCL,
				source.RAPASymbolCappingIndicatorCP,
				source.RAPASymbolCappingIndicatorSL,
				source.RAPASymbolCappingIndicatorCN,
				source.vehicle_unique_id,
				source.source_system_sk,
				GETDATE(),
				GETDATE(),
				@etl_audit_sk
			);

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.[tquote_auto_vehicle_coverage_rapa_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_vehicle_coverage_rapa_wip_temp1];

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