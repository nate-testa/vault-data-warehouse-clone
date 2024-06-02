-- =========================================================================================================================== 
-- Description: This procedures insert pel quote data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/06/2024 			Hernando Gonzalez					1. Created this procedure 
-- 05/08/2024 			Architha Gudimalla					2. Updated @new_last_source_extract_ts 
-- 05/14/2024 			Architha Gudimalla					3. Corrected errors
-- 05/28/2024			Alberto Almario						4. Integrate Premium Adjustments data into EDW - PEL 
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_coverage_wip]

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
		drop table if exists edw_temp.tquote_pel_coverage_wip_temp1;

		WITH 
        acct AS (
			SELECT *
			FROM [edw_stage].[Account] AS a
			WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
			AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
			AND a.PolicyNumber IS NOT NULL
        )
        ,acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.CreatedDate, acct.[Number],
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
            FROM acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountPremium] AS acctvp ON acctvp.AccountId = acct.id
            INNER JOIN [edw_stage].[AccountPremiumFactor] AS acctvpf ON acctvpf.AccountPremiumId = acctvp.id
            WHERE acctvpf.Coverage = 'Excess Liability'
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
        ,FinalTablePremAdj AS (
            SELECT
                PolicyNumber, EffectiveDate, CreatedDate, [Number]
                ,excess_coverage_premium_adjustment_method
                ,excess_coverage_premium_adjustment_factor
                ,excess_coverage_premium_adjustment_retention
                ,excess_coverage_premium_adjustment_retention_reason
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
        )
		,FinalTable AS (
			select 
				PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,policy_history_sk,source_system_sk,
				CreatedDate,UpdatedDate,CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
				DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,CustomerHasPublicProfile,
				LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
				HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
				PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
				CriminalTrafficViolationField,YouthfulOperatorCount,AdultOperatorCount,
				SecondaryInsuredCoverageAmount,UnderinsuredMotoristLiabilityForSecondaryInsured,DefenseInsideLimits,AutoLiabilityExclusion,
				AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit
			from
			(
			select * 
			from
				(
				
				select
				acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
				CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk policy_history_sk,
				0 AS transaction_seq_no, 
				CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
				acco.[Index],acc.CreatedDate,acc.UpdatedDate,
				accof.Field,NULLIF(TRIM(accof.[Value]),'') AS [Value]
				from
					acct as acc
					inner join [edw_stage].[Product] p on acc.ProductId = p.id
					inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
					inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
					left join [edw_core].[tquote_history] tph on tph.quote_no = acc.PolicyNumber
							and tph.effective_dt = acc.EffectiveDate
							and tph.transaction_seq_no = 0
					left join edw_stage.Product pr on acc.ProductId = pr.id
				where
					p.[Name] = 'Personal Excess Liability'
					and acco.ObjectType = 'PersonalExcessLiability'
					and pr.ProductLine = 'PersonalLines'
					and accof.Field IN 
					(
						'CoverageLimit','UnderinsuredMotoristLiability','UnderinsuredLiability','EmploymentPracticesLiabilityLimit',
						'DomesticEmployeeCount','IncludeEmploymentPracticesLiability','DONotForProfitLimit','DOContinuityDate','DOContinuityDateOverride',
						'CustomerHasPublicProfile','LevelOfAttention','LibelSlanderExclusion','PoliticalExclusion','AnimalRelatedLiabilityExclusion',
						'HigherUnderlyingLimitsEndorsement','AILimitedLiability','MinimumEarnedPremiumEndorsement','MinimumEarnedPremiumEndorsementLimit',
						'PremisesLiabilityLimitation','DeletionofCosmeticMarringExclusion','Manuscript','ProfileAdjustment','CriminalTrafficViolation',
						'CriminalTrafficViolationField','YouthfulOperatorCount','AdultOperatorCount',
						'SecondaryInsuredCoverageAmount','UnderinsuredMotoristLiabilityForSecondaryInsured','DefenseInsideLimits','AutoLiabilityExclusion',
						'AutoUnderlyingLimitType','AutoUnderlyingLimitAmountPerOccurrence','AutoUnderlyingLimitAmountForPropertyDamage','HomeUnderlyingLimit'
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
					AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit
					)
			) as pivottable
		)

		SELECT 
            a.*
            ,b.excess_coverage_premium_adjustment_method
			,b.excess_coverage_premium_adjustment_factor
			,b.excess_coverage_premium_adjustment_retention
			,b.excess_coverage_premium_adjustment_retention_reason
		INTO [edw_temp].[tquote_pel_coverage_wip_temp1]
        FROM FinalTable AS a 
        LEFT JOIN FinalTablePremAdj AS b
        ON a.PolicyNumber = b.PolicyNumber
        AND a.EffectiveDate = b.EffectiveDate
        AND a.transaction_seq_no = b.[Number]


		MERGE INTO [edw_core].[tquote_pel_coverage] AS TARGET
		USING (
		    SELECT
		        ttlc.PolicyNumber AS quote_no,
		        ttlc.EffectiveDate AS effective_dt,
		        ttlc.transaction_seq_no AS transaction_seq_no,
		        ttlc.ExpirationDate AS expiration_dt,
		        ttlc.policy_history_sk AS quote_history_sk,
		        ttlc.CoverageLimit AS pel_limit_amt,
		        ttlc.UnderinsuredMotoristLiability AS uninsured_underinsured_motorist_liability_amt,
		        ttlc.UnderinsuredLiability AS uninsured_underinsured_liability_amt,
		        ttlc.EmploymentPracticesLiabilityLimit AS employment_practices_liability_amt,
		        ttlc.DomesticEmployeeCount AS private_staff_ct,
		        ttlc.IncludeEmploymentPracticesLiability AS allegation_by_private_staff_in,
		        ttlc.DONotForProfitLimit AS do_limit_amt,
		        ttlc.DOContinuityDate AS do_continuity_dt,
		        ttlc.DOContinuityDateOverride AS do_continuity_override_dt,
		        ttlc.CustomerHasPublicProfile AS public_profile_in,
		        ttlc.LevelOfAttention AS level_of_attention,
		        ttlc.LibelSlanderExclusion AS libel_slander_exclusion_in,
		        ttlc.PoliticalExclusion AS political_exclusion_in,
		        ttlc.AnimalRelatedLiabilityExclusion AS animal_related_liability_exclusion_in,
		        ttlc.HigherUnderlyingLimitsEndorsement AS higher_underlying_limits_endorsement_in,
		        ttlc.AILimitedLiability AS addl_insured_limited_liability_in,
		        ttlc.MinimumEarnedPremiumEndorsement AS minimum_earned_premium_endorsement_in,
		        replace(ttlc.MinimumEarnedPremiumEndorsementLimit,',','') AS minimum_earned_premium_endorsement_limit_pc,
		        ttlc.PremisesLiabilityLimitation AS premises_liability_limitation_in,
		        ttlc.DeletionofCosmeticMarringExclusion AS deletion_of_cosmetic_marring_exclusion_in,
		        ttlc.Manuscript AS manuscript_in,
		        ttlc.source_system_sk AS source_system_sk,
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        ttlc.SecondaryInsuredCoverageAmount AS secondary_insured_coverage_amt,
		        ttlc.UnderinsuredMotoristLiabilityForSecondaryInsured AS underinsured_motorist_liability_for_secondary_insured_amt,
		        ttlc.DefenseInsideLimits AS defense_inside_limits_in,
		        ttlc.AutoLiabilityExclusion AS auto_liability_exclusion_in,
		        ttlc.AutoUnderlyingLimitType AS auto_underlying_limit_type,
		        ttlc.AutoUnderlyingLimitAmountPerOccurrence AS auto_underlying_limit_per_occurence_amt,
		        ttlc.AutoUnderlyingLimitAmountForPropertyDamage AS auto_underlying_limit_for_property_damage_amt,
		        ttlc.HomeUnderlyingLimit AS home_underlying_limit_amt
				,ttlc.excess_coverage_premium_adjustment_method
				,ttlc.excess_coverage_premium_adjustment_factor
				,ttlc.excess_coverage_premium_adjustment_retention
				,ttlc.excess_coverage_premium_adjustment_retention_reason
		    FROM
		        edw_temp.tquote_pel_coverage_wip_temp1 AS ttlc
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no
		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.pel_limit_amt = SOURCE.pel_limit_amt,
		        TARGET.uninsured_underinsured_motorist_liability_amt = SOURCE.uninsured_underinsured_motorist_liability_amt,
		        TARGET.uninsured_underinsured_liability_amt = SOURCE.uninsured_underinsured_liability_amt,
		        TARGET.employment_practices_liability_amt = SOURCE.employment_practices_liability_amt,
		        TARGET.private_staff_ct = SOURCE.private_staff_ct,
		        TARGET.allegation_by_private_staff_in = SOURCE.allegation_by_private_staff_in,
		        TARGET.do_limit_amt = SOURCE.do_limit_amt,
		        TARGET.do_continuity_dt = SOURCE.do_continuity_dt,
		        TARGET.do_continuity_override_dt = SOURCE.do_continuity_override_dt,
		        TARGET.public_profile_in = SOURCE.public_profile_in,
		        TARGET.level_of_attention = SOURCE.level_of_attention,
		        TARGET.libel_slander_exclusion_in = SOURCE.libel_slander_exclusion_in,
		        TARGET.political_exclusion_in = SOURCE.political_exclusion_in,
		        TARGET.animal_related_liability_exclusion_in = SOURCE.animal_related_liability_exclusion_in,
		        TARGET.higher_underlying_limits_endorsement_in = SOURCE.higher_underlying_limits_endorsement_in,
		        TARGET.addl_insured_limited_liability_in = SOURCE.addl_insured_limited_liability_in,
		        TARGET.minimum_earned_premium_endorsement_in = SOURCE.minimum_earned_premium_endorsement_in,
		        TARGET.minimum_earned_premium_endorsement_limit_pc = SOURCE.minimum_earned_premium_endorsement_limit_pc,
		        TARGET.premises_liability_limitation_in = SOURCE.premises_liability_limitation_in,
		        TARGET.deletion_of_cosmetic_marring_exclusion_in = SOURCE.deletion_of_cosmetic_marring_exclusion_in,
		        TARGET.manuscript_in = SOURCE.manuscript_in,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.secondary_insured_coverage_amt = SOURCE.secondary_insured_coverage_amt,
		        TARGET.underinsured_motorist_liability_for_secondary_insured_amt = SOURCE.underinsured_motorist_liability_for_secondary_insured_amt,
		        TARGET.defense_inside_limits_in = SOURCE.defense_inside_limits_in,
		        TARGET.auto_liability_exclusion_in = SOURCE.auto_liability_exclusion_in,
		        TARGET.auto_underlying_limit_type = SOURCE.auto_underlying_limit_type,
		        TARGET.auto_underlying_limit_per_occurence_amt = SOURCE.auto_underlying_limit_per_occurence_amt,
		        TARGET.auto_underlying_limit_for_property_damage_amt = SOURCE.auto_underlying_limit_for_property_damage_amt,
		        TARGET.home_underlying_limit_amt = SOURCE.home_underlying_limit_amt,
				TARGET.excess_coverage_premium_adjustment_method = SOURCE.excess_coverage_premium_adjustment_method,
				TARGET.excess_coverage_premium_adjustment_factor = SOURCE.excess_coverage_premium_adjustment_factor,
				TARGET.excess_coverage_premium_adjustment_retention = SOURCE.excess_coverage_premium_adjustment_retention,
				TARGET.excess_coverage_premium_adjustment_retention_reason = SOURCE.excess_coverage_premium_adjustment_retention_reason

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no,
		        quote_history_sk, pel_limit_amt, uninsured_underinsured_motorist_liability_amt, uninsured_underinsured_liability_amt,
		        employment_practices_liability_amt, private_staff_ct, allegation_by_private_staff_in, do_limit_amt, do_continuity_dt,
		        do_continuity_override_dt, public_profile_in, level_of_attention, libel_slander_exclusion_in, political_exclusion_in,
		        animal_related_liability_exclusion_in, higher_underlying_limits_endorsement_in, addl_insured_limited_liability_in,
		        minimum_earned_premium_endorsement_in, minimum_earned_premium_endorsement_limit_pc, premises_liability_limitation_in,
		        deletion_of_cosmetic_marring_exclusion_in, manuscript_in, source_system_sk, create_ts, update_ts, etl_audit_sk,
		        secondary_insured_coverage_amt, underinsured_motorist_liability_for_secondary_insured_amt, defense_inside_limits_in, auto_liability_exclusion_in,
		        auto_underlying_limit_type, auto_underlying_limit_per_occurence_amt, auto_underlying_limit_for_property_damage_amt, home_underlying_limit_amt
				,excess_coverage_premium_adjustment_method
				,excess_coverage_premium_adjustment_factor
				,excess_coverage_premium_adjustment_retention
				,excess_coverage_premium_adjustment_retention_reason
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no,
		        SOURCE.quote_history_sk, SOURCE.pel_limit_amt, SOURCE.uninsured_underinsured_motorist_liability_amt, SOURCE.uninsured_underinsured_liability_amt,
		        SOURCE.employment_practices_liability_amt, SOURCE.private_staff_ct, SOURCE.allegation_by_private_staff_in, SOURCE.do_limit_amt, SOURCE.do_continuity_dt,
		        SOURCE.do_continuity_override_dt, SOURCE.public_profile_in, SOURCE.level_of_attention, SOURCE.libel_slander_exclusion_in, SOURCE.political_exclusion_in,
		        SOURCE.animal_related_liability_exclusion_in, SOURCE.higher_underlying_limits_endorsement_in, SOURCE.addl_insured_limited_liability_in,
		        SOURCE.minimum_earned_premium_endorsement_in, SOURCE.minimum_earned_premium_endorsement_limit_pc, SOURCE.premises_liability_limitation_in,
		        SOURCE.deletion_of_cosmetic_marring_exclusion_in, SOURCE.manuscript_in, SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk,
		        SOURCE.secondary_insured_coverage_amt, SOURCE.underinsured_motorist_liability_for_secondary_insured_amt, SOURCE.defense_inside_limits_in, SOURCE.auto_liability_exclusion_in,
		        SOURCE.auto_underlying_limit_type, SOURCE.auto_underlying_limit_per_occurence_amt, SOURCE.auto_underlying_limit_for_property_damage_amt, SOURCE.home_underlying_limit_amt
				,SOURCE.[excess_coverage_premium_adjustment_method]
				,SOURCE.[excess_coverage_premium_adjustment_factor]
				,SOURCE.[excess_coverage_premium_adjustment_retention]
				,SOURCE.[excess_coverage_premium_adjustment_retention_reason]
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_pel_coverage_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_coverage_wip_temp1
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

