SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================================================================================
-- Author:		Hernando Gonzalez
-- Create Date: 2024-04-01
-- Description: This stored procedure insert and update info related to tquote_auto_vehicle_coverage_rapa.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 01/04/24		Hernando Gonzalez			1. Initial Version
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_vehicle_coverage_rapa]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_vehicle_coverage_rapa_temp1];

		SELECT 
			CreatedDate, quote_no, effective_dt, vehicle_no, expiration_dt, transaction_seq_no, quote_history_sk, quote_auto_vehicle_sk, quote_auto_vehicle_coverage_sk
            ,RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			,vehicle_unique_id, source_system_sk
        INTO [edw_temp].[tquote_auto_vehicle_coverage_rapa_temp1]
        FROM
			(
                SELECT
                    acct.CreatedDate, acct.PolicyNumber as quote_no, acct.EffectiveDate as effective_dt, qav.[vehicle_no] as vehicle_no, acctvo.[UniqueId] as vehicle_unique_id,
                    acct.ExpirationDate as expiration_dt, acct.[Number] as transaction_seq_no,
                    qh.quote_history_sk, qav.quote_auto_vehicle_sk, qavc.quote_auto_vehicle_coverage_sk, 
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (SELECT
                        *
                    FROM [edw_stage].[AccountTransaction]
                    WHERE Stage in ('QUOTE','POLICY')
                        --AND IssuedDate > @last_source_extract_ts
						AND CreatedDate > @last_source_extract_ts
                    ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                INNER JOIN [edw_core].[tquote_auto_vehicle] AS qav
                    ON qav.quote_no = acct.PolicyNumber
					AND qav.effective_dt = acct.EffectiveDate
                    AND qav.vehicle_no = acctvo.[Index]
				INNER JOIN [edw_core].[tquote_auto_vehicle_coverage] AS qavc
					ON qavc.quote_no = acct.PolicyNumber
                    AND qavc.effective_dt = CAST(acct.EffectiveDate AS DATE)
                    AND qavc.transaction_seq_no = acct.[Number]
					AND qavc.vehicle_no = qav.vehicle_no
				LEFT JOIN [edw_core].[tquote_history] AS qh 
                    ON qh.quote_no = acct.PolicyNumber
                    AND qh.effective_dt = acct.EffectiveDate
                    AND qh.transaction_seq_no = acct.[Number]
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Symbols', 'Symbols - ISO')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
                )
			) pivottable

		-- Start Insert process
		INSERT INTO [edw_core].[tquote_auto_vehicle_coverage_rapa]
        (
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
        SELECT 
            t1.quote_no,
            t1.effective_dt,
            t1.vehicle_no,
            t1.expiration_dt,
            t1.transaction_seq_no,
            t1.quote_history_sk,
            t1.quote_auto_vehicle_sk, 
            t1.quote_auto_vehicle_coverage_sk,
			t1.RAPABodilyInjuryIndicatedSymbolRelativityChar1, t1.RAPAPropertyDamageIndicatedSymbolRelativityChar1, t1.RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, t1.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, t1.RAPACollisionIndicatedSymbolRelativityChar1, t1.RAPAComprehensiveIndicatedSymbolRelativityChar1, t1.RAPASingleLimitIndicatedSymbolRelativityChar1, t1.RAPABodilyInjuryIndicatedSymbolRelativityChar2, t1.RAPAPropertyDamageIndicatedSymbolRelativityChar2, t1.RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, t1.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, t1.RAPACollisionIndicatedSymbolRelativityChar2, t1.RAPAComprehensiveIndicatedSymbolRelativityChar2, t1.RAPASingleLimitIndicatedSymbolRelativityChar2, t1.RAPABodilyInjuryIndicatedSymbol, t1.RAPAPropertyDamageIndicatedSymbol, t1.RAPAMedicalPaymentsIndicatedSymbol, t1.RAPAPersonalInjuryProtectionIndicatedSymbol, t1.RAPACollisionIndicatedSymbol, t1.RAPAComprehensiveIndicatedSymbol, t1.RAPASingleLimitIndicatedSymbol, t1.RAPABodilyInjuryIndicatedSymbolRelativity, t1.RAPAPropertyDamageIndicatedSymbolRelativity, t1.RAPAMedicalPaymentsIndicatedSymbolRelativity, t1.RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, t1.RAPACollisionIndicatedSymbolRelativity, t1.RAPAComprehensiveIndicatedSymbolRelativity, t1.RAPASingleLimitIndicatedSymbolRelativity, t1.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, t1.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, t1.RAPAComprehensiveNonGlassIndicatedSymbol, t1.RAPAComprehensiveNonGlassIndicatedSymbolRelativity, t1.RAPABodilyInjuryRatingSymbolRelativity, t1.RAPASymbolBI, t1.RAPAPropertyDamageRatingSymbolRelativity, t1.RAPASymbolPD, t1.RAPAMedicalPaymentsRatingSymbolRelativity, t1.RAPASymbolMP, t1.RAPAPersonalInjuryProtectionRatingSymbolRelativity, t1.RAPASymbolNF, t1.RAPACollisionRatingSymbolRelativity, t1.RAPASymbolCL, t1.RAPAComprehensiveRatingSymbolRelativity, t1.RAPASymbolCP, t1.RAPASingleLimitRatingSymbolRelativity, t1.RAPASymbolSL, t1.RAPAComprehensiveNonGlassRatingSymbolRelativity, t1.RAPASymbolCN, t1.RAPASymbolCappingIndicatorBI, t1.RAPASymbolCappingIndicatorPD, t1.RAPASymbolCappingIndicatorMP, t1.RAPASymbolCappingIndicatorNF, t1.RAPASymbolCappingIndicatorCL, t1.RAPASymbolCappingIndicatorCP, t1.RAPASymbolCappingIndicatorSL, t1.RAPASymbolCappingIndicatorCN,	
			t1.vehicle_unique_id,
            t1.source_system_sk,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        FROM 
            [edw_temp].[tquote_auto_vehicle_coverage_rapa_temp1] AS t1
			where t1.RAPASymbolBI is not null
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.[tquote_auto_vehicle_coverage_rapa_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_vehicle_coverage_rapa_temp1];

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