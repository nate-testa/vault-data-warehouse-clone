-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel driver data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 05/28/24		Alberto Almario					1. Integrate Premium Adjustments data into EDW - PEL 
-- 07/09/24		Alberto Almario					2. Add 7 new columns
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpel_coverage]

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
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp1;
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp2;
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp3;

		WITH 
		acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.policychangenumber,
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
            FROM [edw_stage].[AccountTransaction] AS acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
            INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
            INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
            WHERE acct.[State] = 'ISSUED'
			AND acct.PolicyNumber IS NOT NULL
            AND acct.IssuedDate > @last_source_extract_ts
			AND acctvpf.Coverage IN ('Excess Liability')
            AND p.[Name] = 'Personal Excess Liability'
            AND p.ProductLine = 'PersonalLines'
			AND acctvpf.field = 'Adjustment'
			AND acctvpf.FactorMethod <> 'None'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, CONCAT(FinalColumnName, '_factor') AS FinalColumnName, amount           as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, policychangenumber, CONCAT(FinalColumnName, '_retention_reason') AS FinalColumnName, reason	as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )

		SELECT
			PolicyNumber, EffectiveDate, IssuedDate, policychangenumber
			,excess_coverage_premium_adjustment_method
			,excess_coverage_premium_adjustment_factor
			,excess_coverage_premium_adjustment_retention
			,excess_coverage_premium_adjustment_retention_reason
		INTO edw_temp.tpel_coverage_temp2
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
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,policy_history_sk,source_system_sk,
			IssuedDate,CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
			DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,CustomerHasPublicProfile,
			LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
			HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
			PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
			CriminalTrafficViolationField,SecondaryInsuredCoverageAmount,UnderinsuredMotoristLiabilityForSecondaryInsured,DefenseInsideLimits,AutoLiabilityExclusion,
			AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit,EmergencyExtensionNotice,
			CoverageLimitDeductible,AdditionalCoverageLimitDeductible,UnderinsuredMotoristDeductible,UnderinsuredDeductible,EmploymentPracticesLiabilityDeductible,
			AutoInsuranceCompany,HomeInsuranceCompany
		INTO edw_temp.tpel_coverage_temp3
		from
			(
			select * 
			from
				(
				
				select
				act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
				CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.policy_history_sk,
				act.policychangenumber AS transaction_seq_no, 
				CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
				act.IssuedDate as TransactionDate,atvo.[Index],act.IssuedDate,
				atvof.Field,NULLIF(TRIM(atvof.[Value]),'') AS [Value]
				from
					[edw_stage].[AccountTransaction] as act
					inner join edw_stage.Product p on p.Id=act.ProductId
					inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
					inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
					inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
					left join [edw_core].[tpolicy_history] tph on tph.policy_no=act.PolicyNumber
							and tph.effective_dt=act.EffectiveDate
							and tph.transaction_seq_no = act.policychangenumber
					left join edw_stage.Product pr on act.ProductId = pr.id
				where act.[State] = 'ISSUED'
					AND act.PolicyNumber IS NOT NULL
					AND act.IssuedDate > @last_source_extract_ts
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
						'CriminalTrafficViolationField','SecondaryInsuredCoverageAmount','UnderinsuredMotoristLiabilityForSecondaryInsured','DefenseInsideLimits','AutoLiabilityExclusion',
						'AutoUnderlyingLimitType','AutoUnderlyingLimitAmountPerOccurrence','AutoUnderlyingLimitAmountForPropertyDamage','HomeUnderlyingLimit','EmergencyExtensionNotice',
						'CoverageLimitDeductible','AdditionalCoverageLimitDeductible','UnderinsuredMotoristDeductible','UnderinsuredDeductible','EmploymentPracticesLiabilityDeductible',
                    	'AutoInsuranceCompany','HomeInsuranceCompany'
					)
				) as t
			) as t
			pivot 
			(
				max(Value) FOR Field IN 
				(
					CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
					DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,CustomerHasPublicProfile,
					LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
					HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
					PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
					CriminalTrafficViolationField,SecondaryInsuredCoverageAmount,UnderinsuredMotoristLiabilityForSecondaryInsured,DefenseInsideLimits,AutoLiabilityExclusion,
					AutoUnderlyingLimitType,AutoUnderlyingLimitAmountPerOccurrence,AutoUnderlyingLimitAmountForPropertyDamage,HomeUnderlyingLimit,EmergencyExtensionNotice,
					CoverageLimitDeductible,AdditionalCoverageLimitDeductible,UnderinsuredMotoristDeductible,UnderinsuredDeductible,EmploymentPracticesLiabilityDeductible,
					AutoInsuranceCompany,HomeInsuranceCompany
					)
			) as pivottable
		;


		WITH driver_age AS (
			select
				policy_no, effective_dt, transaction_seq_no,
				sum(case driver when 'Youthful' then 1 else 0 end) as youthful_drivers_ct,
				sum(case driver when 'Adult' then 1 else 0 end) as adult_drivers_ct
			from
			(
				SELECT
				tp.policy_no,tp.effective_dt, tph.transaction_seq_no,
				CASE
				    WHEN tp.risk_state_cd in ('AZ', 'CO', 'GA', 'LA') AND DATEDIFF(year, peld.birth_dt, GETDATE()) <= 24 THEN 'Youthful'
				    WHEN tp.risk_state_cd = 'MA' AND (YEAR(GETDATE()) - peld.license_year) <= 4 THEN 'Youthful'
				    WHEN DATEDIFF(year, peld.birth_dt, GETDATE()) <= 25 THEN 'Youthful'
				    ELSE 'Adult'
				END AS driver
				FROM edw_core.tpolicy tp
				INNER JOIN edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk
				INNER JOIN edw_core.tpel_driver peld on peld.policy_history_sk = tph.policy_history_sk 
			) as a
			group by policy_no, effective_dt, transaction_seq_no
		)

		SELECT 
            a.*
			,drv.youthful_drivers_ct
			,drv.adult_drivers_ct
            ,b.excess_coverage_premium_adjustment_method
			,b.excess_coverage_premium_adjustment_factor
			,b.excess_coverage_premium_adjustment_retention
			,b.excess_coverage_premium_adjustment_retention_reason
		INTO [edw_temp].[tpel_coverage_temp1]
        FROM edw_temp.tpel_coverage_temp3 AS a 
        LEFT JOIN edw_temp.tpel_coverage_temp2 AS b
			ON a.PolicyNumber = b.PolicyNumber
			AND a.EffectiveDate = b.EffectiveDate
			AND a.IssuedDate = b.IssuedDate
			AND a.transaction_seq_no = b.policychangenumber
		LEFT JOIN driver_age AS drv 
			ON drv.policy_no = a.PolicyNumber 
			AND drv.effective_dt = cast(a.EffectiveDate as date)
			AND drv.transaction_seq_no = a.transaction_seq_no
			

		INSERT INTO [edw_core].[tpel_coverage]
		(
			policy_no,effective_dt,transaction_effective_dt,expiration_dt,transaction_dt,transaction_seq_no,
			policy_history_sk,pel_limit_amt,uninsured_underinsured_motorist_liability_amt,uninsured_underinsured_liability_amt,
			employment_practices_liability_amt,private_staff_ct,allegation_by_private_staff_in,do_limit_amt,do_continuity_dt,
			do_continuity_override_dt,public_profile_in,level_of_attention,libel_slander_exclusion_in,political_exclusion_in,
			animal_related_liability_exclusion_in,higher_underlying_limits_endorsement_in,addl_insured_limited_liability_in,
			minimum_earned_premium_endorsement_in,minimum_earned_premium_endorsement_limit_pc,premises_liability_limitation_in,
			deletion_of_cosmetic_marring_exclusion_in,manuscript_in,profile_adjustment,criminal_traffic_violation_in,
			criminal_traffic_violation_desc,youthful_drivers_ct,adult_drivers_ct,
			source_system_sk,create_ts,update_ts,etl_audit_sk,
			secondary_insured_coverage_amt,underinsured_motorist_liability_for_secondary_insured_amt,defense_inside_limits_in,auto_liability_exclusion_in,
			auto_underlying_limit_type,auto_underlying_limit_per_occurence_amt,auto_underlying_limit_for_property_damage_amt,home_underlying_limit_amt
			,excess_coverage_premium_adjustment_method
			,excess_coverage_premium_adjustment_factor
			,excess_coverage_premium_adjustment_retention
			,excess_coverage_premium_adjustment_retention_reason
			,emergency_extension_notice_in
			,coverage_deductible_amt
			,additional_coverage_deductible_amt
			,underinsured_motorist_deductible_amt
			,underinsured_deductible_amt
			,employment_practices_liability_deductible_amt
			,current_underlying_auto_insurance_company_nm
			,current_underlying_home_insurance_company_nm
		)
		SELECT
			PolicyNumber AS policy_no,EffectiveDate AS effective_dt,TransactionEffectiveDate AS transaction_effective_dt,
			ExpirationDate AS expiration_dt,TransactionDate AS transaction_dt,transaction_seq_no AS transaction_seq_no,policy_history_sk,
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
			ProfileAdjustment AS profile_adjustment,CriminalTrafficViolation AS criminal_traffic_violation_in,
			CriminalTrafficViolationField AS criminal_traffic_violation_desc,
			youthful_drivers_ct,
			adult_drivers_ct,
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
			,CoverageLimitDeductible AS coverage_deductible_amt
			,AdditionalCoverageLimitDeductible AS additional_coverage_deductible_amt
			,UnderinsuredMotoristDeductible AS underinsured_motorist_deductible_amt
			,UnderinsuredDeductible AS underinsured_deductible_amt
			,EmploymentPracticesLiabilityDeductible AS employment_practices_liability_deductible_amt
			,AutoInsuranceCompany AS current_underlying_auto_insurance_company_nm
			,HomeInsuranceCompany AS current_underlying_home_insurance_company_nm
		FROM edw_temp.tpel_coverage_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tpel_coverage_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp1;
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp2;
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp3;

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
