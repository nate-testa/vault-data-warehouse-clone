SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO 
-- =========================================================================================================================== 
-- Description: This procedures insert and update info related to tpel_vehicle_rapa.
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/06/2024 			Hernando Gonzalez					1. Created this procedure 
-- 05/08/2024 			Architha Gudimalla					2. Updated @new_last_source_extract_ts 
-- 05/14/2024 			Architha Gudimalla					3. Corrected errors
-- 08/03/2024 			Architha Gudimalla					4. Updated tpel_vehicle join to use vehicle_unique_id
-- 08/22/2024			Architha Gudimalla					5. Removed eff_dt from merge
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_vehicle_rapa_wip]

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

		drop table if exists edw_temp.tquote_pel_vehicle_rapa_wip_temp1
		select 
			CreatedDate, UpdatedDate, quote_no, EffectiveDate, vehicle_no, ExpirationDate, transaction_seq_no
			,quote_history_sk
			,quote_pel_vehicle_sk, quote_pel_coverage_sk
			,RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			,source_system_sk
			into edw_temp.tquote_pel_vehicle_rapa_wip_temp1
		from
		(
			select * 
			from
			(
				select
				acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, CAST(acc.EffectiveDate AS DATE) AS EffectiveDate, acco.[Index] AS [vehicle_no], CAST(acc.ExpirationDate AS DATE) AS ExpirationDate
				,0 AS transaction_seq_no
				,tqh.quote_history_sk
				,tqv.quote_pel_vehicle_sk
				,tqc.quote_pel_coverage_sk
				,accof.Field, accof.[Value]
				,CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk
				from (
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				inner join edw_stage.Product p
					on p.Id = acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				left join [edw_core].[tquote_history] tqh
					on tqh.quote_no = acc.PolicyNumber
					and tqh.effective_dt = acc.EffectiveDate
					and tqh.transaction_seq_no = 0
				left join [edw_core].[tquote_pel_vehicle] tqv
					on tqv.quote_no = acc.PolicyNumber
					and tqv.effective_dt = acc.EffectiveDate
					and tqv.transaction_seq_no = 0
					--and tqv.vehicle_no = acco.[Index]
					and tqv.vehicle_unique_id = acco.[UniqueId]
				left join [edw_core].[tquote_pel_coverage] tqc
					on tqc.quote_no = acc.PolicyNumber
					and tqc.effective_dt = CAST(acc.EffectiveDate AS DATE)
					and tqc.transaction_seq_no = 0
				left join edw_stage.Product pr
					on acc.ProductId = pr.id
				where
					acc.PolicyNumber is not null
					--and acc.[Stage] in ('QUOTE','POLICY')
					and p.[Name]='Personal Excess Liability'
					and pr.ProductLine = 'PersonalLines'
					and accof.[Group] in ('Symbols', 'Symbols - ISO')
					and accof.Field IN (
						'RAPABodilyInjuryIndicatedSymbolRelativityChar1','RAPAPropertyDamageIndicatedSymbolRelativityChar1','RAPAMedicalPaymentsIndicatedSymbolRelativityChar1','RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1','RAPACollisionIndicatedSymbolRelativityChar1','RAPAComprehensiveIndicatedSymbolRelativityChar1','RAPASingleLimitIndicatedSymbolRelativityChar1','RAPABodilyInjuryIndicatedSymbolRelativityChar2','RAPAPropertyDamageIndicatedSymbolRelativityChar2','RAPAMedicalPaymentsIndicatedSymbolRelativityChar2','RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2','RAPACollisionIndicatedSymbolRelativityChar2','RAPAComprehensiveIndicatedSymbolRelativityChar2','RAPASingleLimitIndicatedSymbolRelativityChar2','RAPABodilyInjuryIndicatedSymbol','RAPAPropertyDamageIndicatedSymbol','RAPAMedicalPaymentsIndicatedSymbol','RAPAPersonalInjuryProtectionIndicatedSymbol','RAPACollisionIndicatedSymbol','RAPAComprehensiveIndicatedSymbol','RAPASingleLimitIndicatedSymbol','RAPABodilyInjuryIndicatedSymbolRelativity','RAPAPropertyDamageIndicatedSymbolRelativity','RAPAMedicalPaymentsIndicatedSymbolRelativity','RAPAPersonalInjuryProtectionIndicatedSymbolRelativity','RAPACollisionIndicatedSymbolRelativity','RAPAComprehensiveIndicatedSymbolRelativity','RAPASingleLimitIndicatedSymbolRelativity','RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1','RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2','RAPAComprehensiveNonGlassIndicatedSymbol','RAPAComprehensiveNonGlassIndicatedSymbolRelativity','RAPABodilyInjuryRatingSymbolRelativity','RAPASymbolBI','RAPAPropertyDamageRatingSymbolRelativity','RAPASymbolPD','RAPAMedicalPaymentsRatingSymbolRelativity','RAPASymbolMP','RAPAPersonalInjuryProtectionRatingSymbolRelativity','RAPASymbolNF','RAPACollisionRatingSymbolRelativity','RAPASymbolCL','RAPAComprehensiveRatingSymbolRelativity','RAPASymbolCP','RAPASingleLimitRatingSymbolRelativity','RAPASymbolSL','RAPAComprehensiveNonGlassRatingSymbolRelativity','RAPASymbolCN','RAPASymbolCappingIndicatorBI','RAPASymbolCappingIndicatorPD','RAPASymbolCappingIndicatorMP','RAPASymbolCappingIndicatorNF','RAPASymbolCappingIndicatorCL','RAPASymbolCappingIndicatorCP','RAPASymbolCappingIndicatorSL','RAPASymbolCappingIndicatorCN'
					)
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN (
				RAPABodilyInjuryIndicatedSymbolRelativityChar1, RAPAPropertyDamageIndicatedSymbolRelativityChar1, RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, RAPACollisionIndicatedSymbolRelativityChar1, RAPAComprehensiveIndicatedSymbolRelativityChar1, RAPASingleLimitIndicatedSymbolRelativityChar1, RAPABodilyInjuryIndicatedSymbolRelativityChar2, RAPAPropertyDamageIndicatedSymbolRelativityChar2, RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, RAPACollisionIndicatedSymbolRelativityChar2, RAPAComprehensiveIndicatedSymbolRelativityChar2, RAPASingleLimitIndicatedSymbolRelativityChar2, RAPABodilyInjuryIndicatedSymbol, RAPAPropertyDamageIndicatedSymbol, RAPAMedicalPaymentsIndicatedSymbol, RAPAPersonalInjuryProtectionIndicatedSymbol, RAPACollisionIndicatedSymbol, RAPAComprehensiveIndicatedSymbol, RAPASingleLimitIndicatedSymbol, RAPABodilyInjuryIndicatedSymbolRelativity, RAPAPropertyDamageIndicatedSymbolRelativity, RAPAMedicalPaymentsIndicatedSymbolRelativity, RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, RAPACollisionIndicatedSymbolRelativity, RAPAComprehensiveIndicatedSymbolRelativity, RAPASingleLimitIndicatedSymbolRelativity, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, RAPAComprehensiveNonGlassIndicatedSymbol, RAPAComprehensiveNonGlassIndicatedSymbolRelativity, RAPABodilyInjuryRatingSymbolRelativity, RAPASymbolBI, RAPAPropertyDamageRatingSymbolRelativity, RAPASymbolPD, RAPAMedicalPaymentsRatingSymbolRelativity, RAPASymbolMP, RAPAPersonalInjuryProtectionRatingSymbolRelativity, RAPASymbolNF, RAPACollisionRatingSymbolRelativity, RAPASymbolCL, RAPAComprehensiveRatingSymbolRelativity, RAPASymbolCP, RAPASingleLimitRatingSymbolRelativity, RAPASymbolSL, RAPAComprehensiveNonGlassRatingSymbolRelativity, RAPASymbolCN, RAPASymbolCappingIndicatorBI, RAPASymbolCappingIndicatorPD, RAPASymbolCappingIndicatorMP, RAPASymbolCappingIndicatorNF, RAPASymbolCappingIndicatorCL, RAPASymbolCappingIndicatorCP, RAPASymbolCappingIndicatorSL, RAPASymbolCappingIndicatorCN
			)
		) as pivottable

		MERGE INTO [edw_core].[tquote_pel_vehicle_rapa] AS TARGET
		USING (
		    SELECT
		        quote_no,
		        EffectiveDate AS effective_dt,
		        vehicle_no,
		        ExpirationDate AS expiration_dt,
		        transaction_seq_no AS transaction_seq_no,
		        quote_history_sk,
		        quote_pel_vehicle_sk,
		        quote_pel_coverage_sk,
		        RAPABodilyInjuryIndicatedSymbolRelativityChar1,
		        RAPAPropertyDamageIndicatedSymbolRelativityChar1,
		        RAPAMedicalPaymentsIndicatedSymbolRelativityChar1,
		        RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1,
		        RAPACollisionIndicatedSymbolRelativityChar1,
		        RAPAComprehensiveIndicatedSymbolRelativityChar1,
		        RAPASingleLimitIndicatedSymbolRelativityChar1,
		        RAPABodilyInjuryIndicatedSymbolRelativityChar2,
		        RAPAPropertyDamageIndicatedSymbolRelativityChar2,
		        RAPAMedicalPaymentsIndicatedSymbolRelativityChar2,
		        RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2,
		        RAPACollisionIndicatedSymbolRelativityChar2,
		        RAPAComprehensiveIndicatedSymbolRelativityChar2,
		        RAPASingleLimitIndicatedSymbolRelativityChar2,
		        RAPABodilyInjuryIndicatedSymbol,
		        RAPAPropertyDamageIndicatedSymbol,
		        RAPAMedicalPaymentsIndicatedSymbol,
		        RAPAPersonalInjuryProtectionIndicatedSymbol,
		        RAPACollisionIndicatedSymbol,
		        RAPAComprehensiveIndicatedSymbol,
		        RAPASingleLimitIndicatedSymbol,
		        RAPABodilyInjuryIndicatedSymbolRelativity,
		        RAPAPropertyDamageIndicatedSymbolRelativity,
		        RAPAMedicalPaymentsIndicatedSymbolRelativity,
		        RAPAPersonalInjuryProtectionIndicatedSymbolRelativity,
		        RAPACollisionIndicatedSymbolRelativity,
		        RAPAComprehensiveIndicatedSymbolRelativity,
		        RAPASingleLimitIndicatedSymbolRelativity,
		        RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1,
		        RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2,
		        RAPAComprehensiveNonGlassIndicatedSymbol,
		        RAPAComprehensiveNonGlassIndicatedSymbolRelativity,
		        RAPABodilyInjuryRatingSymbolRelativity,
		        RAPASymbolBI,
		        RAPAPropertyDamageRatingSymbolRelativity,
		        RAPASymbolPD,
		        RAPAMedicalPaymentsRatingSymbolRelativity,
		        RAPASymbolMP,
		        RAPAPersonalInjuryProtectionRatingSymbolRelativity,
		        RAPASymbolNF,
		        RAPACollisionRatingSymbolRelativity,
		        RAPASymbolCL,
		        RAPAComprehensiveRatingSymbolRelativity,
		        RAPASymbolCP,
		        RAPASingleLimitRatingSymbolRelativity,
		        RAPASymbolSL,
		        RAPAComprehensiveNonGlassRatingSymbolRelativity,
		        RAPASymbolCN,
		        RAPASymbolCappingIndicatorBI,
		        RAPASymbolCappingIndicatorPD,
		        RAPASymbolCappingIndicatorMP,
		        RAPASymbolCappingIndicatorNF,
		        RAPASymbolCappingIndicatorCL,
		        RAPASymbolCappingIndicatorCP,
		        RAPASymbolCappingIndicatorSL,
		        RAPASymbolCappingIndicatorCN,
		        source_system_sk,
		        getdate() AS create_ts,
		        getdate() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
		    FROM
		        edw_temp.tquote_pel_vehicle_rapa_wip_temp1
		    WHERE
		        RAPASymbolBI IS NOT NULL
		        OR RAPASymbolPD IS NOT NULL
		        OR RAPASymbolNF IS NOT NULL
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.vehicle_no = SOURCE.vehicle_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.quote_pel_vehicle_sk = SOURCE.quote_pel_vehicle_sk,
		        TARGET.quote_pel_coverage_sk = SOURCE.quote_pel_coverage_sk,
		        TARGET.bodily_injury_char1_relativity = SOURCE.RAPABodilyInjuryIndicatedSymbolRelativityChar1,
		        TARGET.property_damage_char1_relativity = SOURCE.RAPAPropertyDamageIndicatedSymbolRelativityChar1,
		        TARGET.medical_payments_char1_relativity = SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativityChar1,
		        TARGET.personal_injury_protection_char1_relativity = SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1,
		        TARGET.collision_char1_relativity = SOURCE.RAPACollisionIndicatedSymbolRelativityChar1,
		        TARGET.comprehensive_char1_relativity = SOURCE.RAPAComprehensiveIndicatedSymbolRelativityChar1,
		        TARGET.single_limit_char1_relativity = SOURCE.RAPASingleLimitIndicatedSymbolRelativityChar1,
		        TARGET.bodily_injury_char2_relativity = SOURCE.RAPABodilyInjuryIndicatedSymbolRelativityChar2,
		        TARGET.property_damage_char2_relativity = SOURCE.RAPAPropertyDamageIndicatedSymbolRelativityChar2,
		        TARGET.medical_payments_char2_relativity = SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativityChar2,
		        TARGET.personal_injury_protection_char2_relativity = SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2,
		        TARGET.collision_char2_relativity = SOURCE.RAPACollisionIndicatedSymbolRelativityChar2,
		        TARGET.comprehensive_char2_relativity = SOURCE.RAPAComprehensiveIndicatedSymbolRelativityChar2,
		        TARGET.single_limit_char2_relativity = SOURCE.RAPASingleLimitIndicatedSymbolRelativityChar2,
		        TARGET.bodily_injury_indicated_symbol = SOURCE.RAPABodilyInjuryIndicatedSymbol,
		        TARGET.property_damage_indicated_symbol = SOURCE.RAPAPropertyDamageIndicatedSymbol,
		        TARGET.medical_payments_indicated_symbol = SOURCE.RAPAMedicalPaymentsIndicatedSymbol,
		        TARGET.personal_injury_protection_indicated_symbol = SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbol,
		        TARGET.collision_indicated_symbol = SOURCE.RAPACollisionIndicatedSymbol,
		        TARGET.comprehensive_indicated_symbol = SOURCE.RAPAComprehensiveIndicatedSymbol,
		        TARGET.single_limit_indicated_symbol = SOURCE.RAPASingleLimitIndicatedSymbol,
		        TARGET.bodily_injury_relativity = SOURCE.RAPABodilyInjuryIndicatedSymbolRelativity,
		        TARGET.property_damage_relativity = SOURCE.RAPAPropertyDamageIndicatedSymbolRelativity,
		        TARGET.medical_payments_relativity = SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativity,
		        TARGET.personal_injury_protection_relativity = SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativity,
		        TARGET.collision_relativity = SOURCE.RAPACollisionIndicatedSymbolRelativity,
		        TARGET.comprehensive_relativity = SOURCE.RAPAComprehensiveIndicatedSymbolRelativity,
		        TARGET.single_limit_relativity = SOURCE.RAPASingleLimitIndicatedSymbolRelativity,
		        TARGET.comprehensive_non_glass_relativity_char1 = SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1,
		        TARGET.comprehensive_non_glass_relativity_char2 = SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2,
		        TARGET.comprehensive_non_glass_indicated_symbol = SOURCE.RAPAComprehensiveNonGlassIndicatedSymbol,
		        TARGET.comprehensive_non_glass_symbol_relativity = SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativity,
		        TARGET.bodily_injury_rating_symbol_relativity = SOURCE.RAPABodilyInjuryRatingSymbolRelativity,
		        TARGET.bodily_injury_symbol = SOURCE.RAPASymbolBI,
		        TARGET.property_damage_rating_symbol_relativity = SOURCE.RAPAPropertyDamageRatingSymbolRelativity,
		        TARGET.property_damage_symbol = SOURCE.RAPASymbolPD,
		        TARGET.medical_payments_rating_symbol_relativity = SOURCE.RAPAMedicalPaymentsRatingSymbolRelativity,
		        TARGET.medical_payments_symbol = SOURCE.RAPASymbolMP,
		        TARGET.personal_injury_protection_rating_symbol_relativity = SOURCE.RAPAPersonalInjuryProtectionRatingSymbolRelativity,
		        TARGET.personal_injury_protection_symbol = SOURCE.RAPASymbolNF,
		        TARGET.collision_rating_symbol_relativity = SOURCE.RAPACollisionRatingSymbolRelativity,
		        TARGET.collision_symbol = SOURCE.RAPASymbolCL,
		        TARGET.comprehensive_rating_symbol_relativity = SOURCE.RAPAComprehensiveRatingSymbolRelativity,
		        TARGET.comprehensive_symbol = SOURCE.RAPASymbolCP,
		        TARGET.single_limit_rating_symbol_relativity = SOURCE.RAPASingleLimitRatingSymbolRelativity,
		        TARGET.single_limit_symbol = SOURCE.RAPASymbolSL,
		        TARGET.comprehensive_non_glass_rating_symbol_relativity = SOURCE.RAPAComprehensiveNonGlassRatingSymbolRelativity,
		        TARGET.comprehensive_non_glass_symbol = SOURCE.RAPASymbolCN,
		        TARGET.bodily_injury_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorBI,
		        TARGET.property_damage_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorPD,
		        TARGET.medical_payments_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorMP,
		        TARGET.personal_injury_protection_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorNF,
		        TARGET.collision_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorCL,
		        TARGET.comprehensive_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorCP,
		        TARGET.single_limit_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorSL,
		        TARGET.comprehensive_non_glass_symbol_capping_in = SOURCE.RAPASymbolCappingIndicatorCN,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, vehicle_no, expiration_dt, transaction_seq_no, quote_history_sk,
		        quote_pel_vehicle_sk, quote_pel_coverage_sk,
		        bodily_injury_char1_relativity, property_damage_char1_relativity, medical_payments_char1_relativity, personal_injury_protection_char1_relativity, collision_char1_relativity, comprehensive_char1_relativity, single_limit_char1_relativity, bodily_injury_char2_relativity, property_damage_char2_relativity, medical_payments_char2_relativity, personal_injury_protection_char2_relativity, collision_char2_relativity, comprehensive_char2_relativity, single_limit_char2_relativity, bodily_injury_indicated_symbol, property_damage_indicated_symbol, medical_payments_indicated_symbol, personal_injury_protection_indicated_symbol, collision_indicated_symbol, comprehensive_indicated_symbol, single_limit_indicated_symbol, bodily_injury_relativity, property_damage_relativity, medical_payments_relativity, personal_injury_protection_relativity, collision_relativity, comprehensive_relativity, single_limit_relativity, comprehensive_non_glass_relativity_char1, comprehensive_non_glass_relativity_char2, comprehensive_non_glass_indicated_symbol, comprehensive_non_glass_symbol_relativity, bodily_injury_rating_symbol_relativity, bodily_injury_symbol, property_damage_rating_symbol_relativity, property_damage_symbol, medical_payments_rating_symbol_relativity, medical_payments_symbol, personal_injury_protection_rating_symbol_relativity, personal_injury_protection_symbol, collision_rating_symbol_relativity, collision_symbol, comprehensive_rating_symbol_relativity, comprehensive_symbol, single_limit_rating_symbol_relativity, single_limit_symbol, comprehensive_non_glass_rating_symbol_relativity, comprehensive_non_glass_symbol, bodily_injury_symbol_capping_in, property_damage_symbol_capping_in, medical_payments_symbol_capping_in, personal_injury_protection_symbol_capping_in, collision_symbol_capping_in, comprehensive_symbol_capping_in, single_limit_symbol_capping_in, comprehensive_non_glass_symbol_capping_in,
		        source_system_sk, create_ts, update_ts, etl_audit_sk
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.vehicle_no, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.quote_pel_vehicle_sk, SOURCE.quote_pel_coverage_sk,
		        SOURCE.RAPABodilyInjuryIndicatedSymbolRelativityChar1, SOURCE.RAPAPropertyDamageIndicatedSymbolRelativityChar1, SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativityChar1, SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar1, SOURCE.RAPACollisionIndicatedSymbolRelativityChar1, SOURCE.RAPAComprehensiveIndicatedSymbolRelativityChar1, SOURCE.RAPASingleLimitIndicatedSymbolRelativityChar1, SOURCE.RAPABodilyInjuryIndicatedSymbolRelativityChar2, SOURCE.RAPAPropertyDamageIndicatedSymbolRelativityChar2, SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativityChar2, SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativityChar2, SOURCE.RAPACollisionIndicatedSymbolRelativityChar2, SOURCE.RAPAComprehensiveIndicatedSymbolRelativityChar2, SOURCE.RAPASingleLimitIndicatedSymbolRelativityChar2, SOURCE.RAPABodilyInjuryIndicatedSymbol, SOURCE.RAPAPropertyDamageIndicatedSymbol, SOURCE.RAPAMedicalPaymentsIndicatedSymbol, SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbol, SOURCE.RAPACollisionIndicatedSymbol, SOURCE.RAPAComprehensiveIndicatedSymbol, SOURCE.RAPASingleLimitIndicatedSymbol, SOURCE.RAPABodilyInjuryIndicatedSymbolRelativity, SOURCE.RAPAPropertyDamageIndicatedSymbolRelativity, SOURCE.RAPAMedicalPaymentsIndicatedSymbolRelativity, SOURCE.RAPAPersonalInjuryProtectionIndicatedSymbolRelativity, SOURCE.RAPACollisionIndicatedSymbolRelativity, SOURCE.RAPAComprehensiveIndicatedSymbolRelativity, SOURCE.RAPASingleLimitIndicatedSymbolRelativity, SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar1, SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativityChar2, SOURCE.RAPAComprehensiveNonGlassIndicatedSymbol, SOURCE.RAPAComprehensiveNonGlassIndicatedSymbolRelativity, SOURCE.RAPABodilyInjuryRatingSymbolRelativity, SOURCE.RAPASymbolBI, SOURCE.RAPAPropertyDamageRatingSymbolRelativity, SOURCE.RAPASymbolPD, SOURCE.RAPAMedicalPaymentsRatingSymbolRelativity, SOURCE.RAPASymbolMP, SOURCE.RAPAPersonalInjuryProtectionRatingSymbolRelativity, SOURCE.RAPASymbolNF, SOURCE.RAPACollisionRatingSymbolRelativity, SOURCE.RAPASymbolCL, SOURCE.RAPAComprehensiveRatingSymbolRelativity, SOURCE.RAPASymbolCP, SOURCE.RAPASingleLimitRatingSymbolRelativity, SOURCE.RAPASymbolSL, SOURCE.RAPAComprehensiveNonGlassRatingSymbolRelativity, SOURCE.RAPASymbolCN, SOURCE.RAPASymbolCappingIndicatorBI, SOURCE.RAPASymbolCappingIndicatorPD, SOURCE.RAPASymbolCappingIndicatorMP, SOURCE.RAPASymbolCappingIndicatorNF, SOURCE.RAPASymbolCappingIndicatorCL, SOURCE.RAPASymbolCappingIndicatorCP, SOURCE.RAPASymbolCappingIndicatorSL, SOURCE.RAPASymbolCappingIndicatorCN,
		        SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_pel_vehicle_rapa_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_vehicle_rapa_wip_temp1
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