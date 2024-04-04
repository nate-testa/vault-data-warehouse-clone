SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Hernando Gonzalez
-- Create Date: 2024-04-01
-- Description: This stored procedure insert and update info related to tpel_vehicle_rapa.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_vehicle_rapa]

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

		drop table if exists edw_temp.tquote_pel_vehicle_rapa_temp1
		select 
			CreatedDate, quote_no, EffectiveDate, vehicle_no, ExpirationDate, transaction_seq_no
			,quote_history_sk
			,quote_pel_vehicle_sk, quote_pel_coverage_sk
			,RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			,source_system_sk
			into edw_temp.tquote_pel_vehicle_rapa_temp1
		from
		(
			select * 
			from
			(
				select
				act.CreatedDate, act.PolicyNumber as quote_no, CAST(act.EffectiveDate AS DATE) AS EffectiveDate, atvo.[Index] AS [vehicle_no], CAST(act.ExpirationDate AS DATE) AS ExpirationDate
				,act.[Number] AS transaction_seq_no
				,tqh.quote_history_sk
				,tqv.quote_pel_vehicle_sk
				,tqc.quote_pel_coverage_sk
				,atvof.Field, atvof.[Value]
				,CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk
				from edw_stage.AccountTransaction act
				inner join edw_stage.Product p
					on p.Id = act.ProductId
				inner join edw_stage.AccountTransactionVersion atv
					on act.Id = atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo
					on atv.Id = atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof
					on atvo.Id = atvof.VersionObjectId
				left join [edw_core].[tquote_history] tqh
					on tqh.quote_no = act.PolicyNumber
					and tqh.effective_dt = act.EffectiveDate
					and tqh.transaction_seq_no = act.[Number]
				left join [edw_core].[tquote_pel_vehicle] tqv
					on tqv.quote_no = act.PolicyNumber
					and tqv.effective_dt = act.EffectiveDate
					and tqv.transaction_seq_no = act.[Number]
				left join [edw_core].[tquote_pel_coverage] tqc
					on tqc.quote_no = act.PolicyNumber
					and tqc.effective_dt = CAST(act.EffectiveDate AS DATE)
					and tqc.transaction_seq_no = act.[Number]
				left join edw_stage.Product pr
					on act.ProductId = pr.id
				where
					act.PolicyNumber is not null and
					act.[State] in ('QUOTE','POLICY')
					and p.[Name]='Personal Excess Liability'
					and pr.ProductLine = 'PersonalLines'
					and atvof.[Group] in ('Symbols', 'Symbols - ISO')
					and atvof.Field IN (
						'RAPABodilyInjuryIndicatedSymbolRelativityChar1','RAPAPropertyDamageIndicatedSymbolRelativityChar1','RAPAMedicalPaymentsIndicatedSymbolRelativityChar1','RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1','RAPACollisionIndicatedSymbolRelativityChar1','RAPAComprehensiveIndicatedSymbolRelativityChar1','RAPASingleLimitIndicatedSymbolRelativityChar1','RAPABodilyInjuryIndicatedSymbolRelativityChar2','RAPAPropertyDamageIndicatedSymbolRelativityChar2','RAPAMedicalPaymentsIndicatedSymbolRelativityChar2','RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2','RAPACollisionIndicatedSymbolRelativityChar2','RAPAComprehensiveIndicatedSymbolRelativityChar2','RAPASingleLimitIndicatedSymbolRelativityChar2','RAPABodilyInjuryIndicatedSymbol','RAPAPropertyDamageIndicatedSymbol','RAPAMedicalPaymentsIndicatedSymbol','RAPAPersonalInjuryProtectionIndicatedSymbol','RAPACollisionIndicatedSymbol','RAPAComprehensiveIndicatedSymbol','RAPASingleLimitIndicatedSymbol','RAPABodilyInjuryIndicatedSymbolRelativity','RAPAPropertyDamageIndicatedSymbolRelativity','RAPAMedicalPaymentsIndicatedSymbolRelativity','RAPAPersonalInjuryProtectionIndicatedSymbolRelativity','RAPACollisionIndicatedSymbolRelativity','RAPAComprehensiveIndicatedSymbolRelativity','RAPASingleLimitIndicatedSymbolRelativity','RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1','RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2','RAPAComprehensiveNonGlassIndicatedSymbol','RAPAComprehensiveNonGlassIndicatedSymbolRelativity','RAPABodilyInjuryRatingSymbolRelativity','RAPASymbolBI','RAPAPropertyDamageRatingSymbolRelativity','RAPASymbolPD','RAPAMedicalPaymentsRatingSymbolRelativity','RAPASymbolMP','RAPAPersonalInjuryProtectionRatingSymbolRelativity','RAPASymbolNF','RAPACollisionRatingSymbolRelativity','RAPASymbolCL','RAPAComprehensiveRatingSymbolRelativity','RAPASymbolCP','RAPASingleLimitRatingSymbolRelativity','RAPASymbolSL','RAPAComprehensiveNonGlassRatingSymbolRelativity','RAPASymbolCN','RAPASymbolCappingIndicatorBI','RAPASymbolCappingIndicatorPD','RAPASymbolCappingIndicatorMP','RAPASymbolCappingIndicatorNF','RAPASymbolCappingIndicatorCL','RAPASymbolCappingIndicatorCP','RAPASymbolCappingIndicatorSL','RAPASymbolCappingIndicatorCN'
					)
					and act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN (
				RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			)
		) as pivottable

		INSERT INTO [edw_core].[tquote_pel_vehicle_rapa]
		(
			quote_no, effective_dt, vehicle_no, expiration_dt, transaction_seq_no, quote_history_sk
			,quote_pel_vehicle_sk, quote_pel_coverage_sk
			,bodily_injury_char1_relativity, property_damage_char1_relativity, medical_payments_char1_relativity, personal_injury_protection_char1_relativity, collision_char1_relativity, comprehensive_char1_relativity, single_limit_char1_relativity, bodily_injury_char2_relativity, property_damage_char2_relativity, medical_payments_char2_relativity, personal_injury_protection_char2_relativity, collision_char2_relativity, comprehensive_char2_relativity, single_limit_char2_relativity, bodily_injury_indicated_symbol, property_damage_indicated_symbol, medical_payments_indicated_symbol, personal_injury_protection_indicated_symbol, collision_indicated_symbol, comprehensive_indicated_symbol, single_limit_indicated_symbol, bodily_injury_relativity, property_damage_relativity, medical_payments_relativity, personal_injury_protection_relativity, collision_relativity, comprehensive_relativity, single_limit_relativity, comprehensive_non_glass_relativity_char1, comprehensive_non_glass_relativity_char2, comprehensive_non_glass_indicated_symbol, comprehensive_non_glass_symbol_relativity, bodily_injury_rating_symbol_relativity, bodily_injury_symbol, property_damage_rating_symbol_relativity, property_damage_symbol, medical_payments_rating_symbol_relativity, medical_payments_symbol, personal_injury_protection_rating_symbol_relativity, personal_injury_protection_symbol, collision_rating_symbol_relativity, collision_symbol, comprehensive_rating_symbol_relativity, comprehensive_symbol, single_limit_rating_symbol_relativity, single_limit_symbol, comprehensive_non_glass_rating_symbol_relativity, comprehensive_non_glass_symbol, bodily_injury_symbol_capping_in, property_damage_symbol_capping_in, medical_payments_symbol_capping_in, personal_injury_protection_symbol_capping_in, collision_symbol_capping_in, comprehensive_symbol_capping_in, single_limit_symbol_capping_in, comprehensive_non_glass_symbol_capping_in
			,[source_system_sk], [create_ts], [update_ts], [etl_audit_sk]
		)
		SELECT
			quote_no, EffectiveDate AS effective_dt, vehicle_no
			,ExpirationDate AS expiration_dt, transaction_seq_no AS transaction_seq_no
			,quote_history_sk
			,quote_pel_vehicle_sk, quote_pel_coverage_sk
			,RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			,source_system_sk, getdate() AS create_ts, getdate() AS update_ts, @etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_pel_vehicle_rapa_temp1
			where RAPASymbolBI is not null
			or RAPASymbolPD is not null
			or RAPASymbolNF is not null

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_vehicle_rapa_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpel_vehicle_rapa_temp1
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