-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel quote driver data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 05/28/24		Alberto Almario					1. Integrate Premium Adjustments data into EDW - PEL 
-- =============================================
CREATE or alter  PROCEDURE [edw_core].[sp_tquote_pel_coverage]

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

		declare @sql nvarchar(max)
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp2;
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp3;

		WITH 
        acct AS (
            SELECT
                *
            FROM [edw_stage].[AccountTransaction]
            WHERE Stage IN ('QUOTE','POLICY')
			AND PolicyNumber IS NOT NULL
            AND CreatedDate > @last_source_extract_ts
        )
        ,acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.CreatedDate, acct.[Number],
                acctvpf.AccountTransactionVersionPremiumId,
                acctvpf.Coverage,
                CONCAT(
                    CASE 
                        WHEN Coverage = 'Excess Liability' THEN 'excess_coverage'
                        ELSE LOWER(REPLACE(Coverage,' ','_'))
                    END
                    ,'_premium_adjustment'
                ) AS FinalColumnName,
                acctvpf.FactorMethod AS method,
                CONVERT(nvarchar(3000), acctvpf.Factor) AS amount,
                acctvpf.Retention AS [retention],
                acctvpf.Reason AS reason
            FROM [edw_stage].[AccountTransaction] as acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
            INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
            INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
            WHERE acct.Stage IN ('QUOTE','POLICY')
			AND acct.PolicyNumber IS NOT NULL
            AND acct.CreatedDate > @last_source_extract_ts
			AND acctvpf.Coverage IN ('Excess Liability')
            AND p.[Name] = 'Personal Excess Liability'
            AND p.ProductLine = 'PersonalLines'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           	as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_factor') AS FinalColumnName, amount           	as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   	as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_retention_reason') AS FinalColumnName, reason	as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )


		SELECT
			PolicyNumber, EffectiveDate, CreatedDate, [Number]
			,excess_coverage_premium_adjustment_method
			,excess_coverage_premium_adjustment_factor
			,excess_coverage_premium_adjustment_retention
			,excess_coverage_premium_adjustment_retention_reason
		INTO edw_temp.tquote_pel_coverage_temp2
		FROM acctvpf_unpivot
		PIVOT 
		(
			MAX(FinalValue) FOR FinalColumnName IN (
				excess_coverage_premium_adjustment_method
				,excess_coverage_premium_adjustment_factor
				,excess_coverage_premium_adjustment_retention
				,excess_coverage_premium_adjustment_retention_reason
			)
		) AS pvt


		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,policy_history_sk,source_system_sk,
			CreatedDate,CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
			DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,CustomerHasPublicProfile,
			LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
			HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
			PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
			CriminalTrafficViolationField,YouthfulOperatorCount,AdultOperatorCount,
			SecondaryInsuredCoverageAmount,UnderinsuredMotoristLiabilityForSecondaryInsured,DefenseInsideLimits,AutoLiabilityExclusion,
			AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit,
			EmergencyExtensionNotice
		INTO edw_temp.tquote_pel_coverage_temp3
		from
		(
		select * 
		from
			(
			
			select
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk policy_history_sk,
			act.[Number] AS transaction_seq_no, 
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			atvo.[Index],act.CreatedDate,
			atvof.Field,NULLIF(TRIM(atvof.[Value]),'') AS [Value]
			from
				[edw_stage].[AccountTransaction] as act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tquote_history] tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.number
				left join edw_stage.Product pr on act.ProductId = pr.id
			WHERE act.Stage IN ('QUOTE','POLICY')
				AND act.PolicyNumber IS NOT NULL
				AND act.CreatedDate > @last_source_extract_ts
				AND p.[Name]='Personal Excess Liability'
				and atvo.ObjectType='PersonalExcessLiability'
				and pr.ProductLine = 'PersonalLines'
				and atvof.Field IN 
				(
					'CoverageLimit','UnderinsuredMotoristLiability','UnderinsuredLiability','EmploymentPracticesLiabilityLimit',
					'DomesticEmployeeCount','IncludeEmploymentPracticesLiability','DONotForProfitLimit','DOContinuityDate','DOContinuityDateOverride',
					'CustomerHasPublicProfile','LevelOfAttention','LibelSlanderExclusion','PoliticalExclusion','AnimalRelatedLiabilityExclusion',
					'HigherUnderlyingLimitsEndorsement','AILimitedLiability','MinimumEarnedPremiumEndorsement','MinimumEarnedPremiumEndorsementLimit',
					'PremisesLiabilityLimitation','DeletionofCosmeticMarringExclusion','Manuscript','ProfileAdjustment','CriminalTrafficViolation',
					'CriminalTrafficViolationField','YouthfulOperatorCount','AdultOperatorCount',
					'SecondaryInsuredCoverageAmount','UnderinsuredMotoristLiabilityForSecondaryInsured','DefenseInsideLimits','AutoLiabilityExclusion',
					'AutoUnderlyingLimitType','AutoUnderlyingLimitAmountPerOccurrence','AutoUnderlyingLimitAmountForPropertyDamage','HomeUnderlyingLimit',
					'EmergencyExtensionNotice'
				)
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN 
			(
				CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
				DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,
				CustomerHasPublicProfile,LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
				HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
				PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
				CriminalTrafficViolationField,YouthfulOperatorCount,AdultOperatorCount,
				SecondaryInsuredCoverageAmount,UnderinsuredMotoristLiabilityForSecondaryInsured,DefenseInsideLimits,AutoLiabilityExclusion,
				AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit,
				EmergencyExtensionNotice
				)
		) as pivottable


		SELECT 
            a.*
            ,b.excess_coverage_premium_adjustment_method
			,b.excess_coverage_premium_adjustment_factor
			,b.excess_coverage_premium_adjustment_retention
			,b.excess_coverage_premium_adjustment_retention_reason
		INTO [edw_temp].[tquote_pel_coverage_temp1]
        FROM [edw_temp].[tquote_pel_coverage_temp3] AS a 
        LEFT JOIN [edw_temp].[tquote_pel_coverage_temp2] AS b
			ON a.PolicyNumber = b.PolicyNumber
			AND a.EffectiveDate = b.EffectiveDate
			AND a.CreatedDate = b.CreatedDate
			AND a.transaction_seq_no = b.[Number]


		INSERT INTO [edw_core].[tquote_pel_coverage]
		(
			quote_no,effective_dt,expiration_dt,transaction_seq_no,
			quote_history_sk,pel_limit_amt,uninsured_underinsured_motorist_liability_amt,uninsured_underinsured_liability_amt,
			employment_practices_liability_amt,private_staff_ct,allegation_by_private_staff_in,do_limit_amt,do_continuity_dt,
			do_continuity_override_dt,public_profile_in,level_of_attention,libel_slander_exclusion_in,political_exclusion_in,
			animal_related_liability_exclusion_in,higher_underlying_limits_endorsement_in,addl_insured_limited_liability_in,
			minimum_earned_premium_endorsement_in,minimum_earned_premium_endorsement_limit_pc,premises_liability_limitation_in,
			deletion_of_cosmetic_marring_exclusion_in,manuscript_in,--profile_adjustment,
			--criminal_traffic_violation_in,
			--criminal_traffic_violation_desc,
			--youthful_drivers_ct,adult_drivers_ct,
			source_system_sk,create_ts,update_ts,etl_audit_sk,
			secondary_insured_coverage_amt,underinsured_motorist_liability_for_secondary_insured_amt,defense_inside_limits_in,auto_liability_exclusion_in,
			auto_underlying_limit_type,auto_underlying_limit_per_occurence_amt,auto_underlying_limit_for_property_damage_amt,home_underlying_limit_amt
			,excess_coverage_premium_adjustment_method
			,excess_coverage_premium_adjustment_factor
			,excess_coverage_premium_adjustment_retention
			,excess_coverage_premium_adjustment_retention_reason
			,emergency_extension_notice_in
		)
		SELECT
			ttlc.PolicyNumber AS policy_no,ttlc.EffectiveDate AS effective_dt,
			ExpirationDate AS expiration_dt,transaction_seq_no AS transaction_seq_no,policy_history_sk,
			CoverageLimit AS pel_limit_amt,UnderinsuredMotoristLiability AS uninsured_underinsured_motorist_liability_amt,
			UnderinsuredLiability AS uninsured_underinsured_liability_amt,
			EmploymentPracticesLiabilityLimit AS employment_practices_liability_amt,
			DomesticEmployeeCount AS private_staff_ct,
			IncludeEmploymentPracticesLiability AS allegation_by_private_staff_in,DONotForProfitLimit AS do_limit_amt,
			DOContinuityDate AS do_continuity_dt,DOContinuityDateOverride AS do_continuity_override_dt,
			CustomerHasPublicProfile AS public_profile_in,LevelOfAttention AS level_of_attention,
			LibelSlanderExclusion as libel_slander_exclusion_in,PoliticalExclusion AS political_exclusion_in,
			AnimalRelatedLiabilityExclusion as animal_related_liability_exclusion_in,
			HigherUnderlyingLimitsEndorsement AS higher_underlying_limits_endorsement_in,
			AILimitedLiability AS addl_insured_limited_liability_in,
			MinimumEarnedPremiumEndorsement AS minimum_earned_premium_endorsement_in,
			MinimumEarnedPremiumEndorsementLimit AS minimum_earned_premium_endorsement_limit_pc,
			PremisesLiabilityLimitation AS premises_liability_limitation_in,
			DeletionofCosmeticMarringExclusion AS deletion_of_cosmetic_marring_exclusion_in,Manuscript AS manuscript_in,
			--ProfileAdjustment AS profile_adjustment,
			--CriminalTrafficViolation AS criminal_traffic_violation_in,
			--CriminalTrafficViolationField AS criminal_traffic_violation_desc,
			--YouthfulOperatorCount AS youthful_drivers_ct,
			--AdultOperatorCount AS adult_drivers_ct,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk,
			SecondaryInsuredCoverageAmount AS secondary_insured_coverage_amt,UnderinsuredMotoristLiabilityForSecondaryInsured AS underinsured_motorist_liability_for_secondary_insured_amt,
			DefenseInsideLimits AS defense_inside_limits_in,AutoLiabilityExclusion AS auto_liability_exclusion_in,
			AutoUnderlyingLimitType AS auto_underlying_limit_type,AutoUnderlyingLimitAmountPerOccurrence AS auto_underlying_limit_per_occurence_amt,
			AutoUnderlyingLimitAmountForPropertyDamage AS auto_underlying_limit_for_property_damage_amt,HomeUnderlyingLimit AS home_underlying_limit_amt
			,excess_coverage_premium_adjustment_method
			,excess_coverage_premium_adjustment_factor
			,excess_coverage_premium_adjustment_retention
			,excess_coverage_premium_adjustment_retention_reason
			,EmergencyExtensionNotice AS emergency_extension_notice_in
		FROM
			edw_temp.tquote_pel_coverage_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_coverage_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp2;
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_temp3;

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

