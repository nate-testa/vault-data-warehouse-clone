-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel driver data
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
		drop table if exists edw_temp.tpel_coverage_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,policy_history_sk,source_system_sk,
			IssuedDate,CoverageLimit,UnderinsuredMotoristLiability,UnderinsuredLiability,EmploymentPracticesLiabilityLimit,
			DomesticEmployeeCount,IncludeEmploymentPracticesLiability,DONotForProfitLimit,DOContinuityDate,DOContinuityDateOverride,CustomerHasPublicProfile,
			LevelOfAttention,LibelSlanderExclusion,PoliticalExclusion,AnimalRelatedLiabilityExclusion,
			HigherUnderlyingLimitsEndorsement,AILimitedLiability,MinimumEarnedPremiumEndorsement,MinimumEarnedPremiumEndorsementLimit,
			PremisesLiabilityLimitation,DeletionofCosmeticMarringExclusion,Manuscript,ProfileAdjustment,CriminalTrafficViolation,
			CriminalTrafficViolationField,YouthfulOperatorCount,AdultOperatorCount
			into edw_temp.tpel_coverage_temp1
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
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tpolicy_history] tph on tph.policy_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.policychangenumber
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
			act.PolicyNumber is not null and
				act.[State] ='ISSUED'
				and p.[Name]='Personal Excess Liability'
				and atvo.ObjectType='PersonalExcessLiability'
				and pr.ProductLine = 'PersonalLines'
				and atvof.Field IN 
				(
					'CoverageLimit','UnderinsuredMotoristLiability','UnderinsuredLiability','EmploymentPracticesLiabilityLimit',
					'DomesticEmployeeCount','IncludeEmploymentPracticesLiability','DONotForProfitLimit','DOContinuityDate','DOContinuityDateOverride',
					'CustomerHasPublicProfile','LevelOfAttention','LibelSlanderExclusion','PoliticalExclusion','AnimalRelatedLiabilityExclusion',
					'HigherUnderlyingLimitsEndorsement','AILimitedLiability','MinimumEarnedPremiumEndorsement','MinimumEarnedPremiumEndorsementLimit',
					'PremisesLiabilityLimitation','DeletionofCosmeticMarringExclusion','Manuscript','ProfileAdjustment','CriminalTrafficViolation',
					'CriminalTrafficViolationField','YouthfulOperatorCount','AdultOperatorCount'
				)
				and act.IssuedDate>@last_source_extract_ts
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
				CriminalTrafficViolationField,YouthfulOperatorCount,AdultOperatorCount
				)
		) as pivottable

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
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			ttlc.PolicyNumber AS policy_no,ttlc.EffectiveDate AS effective_dt,TransactionEffectiveDate AS transaction_effective_dt,
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
			YouthfulOperatorCount AS youthful_drivers_ct,
			AdultOperatorCount AS adult_drivers_ct,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tpel_coverage_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tpel_coverage_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpel_coverage_temp1
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

