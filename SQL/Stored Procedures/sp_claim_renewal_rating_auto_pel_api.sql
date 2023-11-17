-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 11/15/2023
-- Description: This procedures inserts and updates data for claim renewal rating for auto and pel
---------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/15/2023		Mohammed Yunus				1. Created this procedure 
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_renewal_rating_auto_pel_api]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF EXISTS edw_temp.claim_renewal_rating_auto_pel_api_temp1

		SELECT
		cl.loss_dt as IncidentDate,
		cl.policy_no as PolicyNumber,
		cl.claim_no as FileNumber,
		l.cause_of_loss_desc as IncidentType,
		NULL as IncidentDescription,
		NULL as IncidentCode,
		cl.claim_status as IncidentStatus,
		TotalPayout,BodilyInjuryPayment,CollisionPayment,
		ComprehensivePayment,GlassPayment,MedicalExpensePayment,MedicalPaymentPayment,
		PropertyDamagePayment,PersonalInjuryProtectionPayment,SpousalLiabilityPayment,
		TowingAndLaborPayment,UninsuredMotoristPayment,UnderinsuredMotoristPayment
		INTO edw_temp.claim_renewal_rating_auto_pel_api_temp1
		FROM
		edw_core.tclaim cl
		LEFT JOIN edw_core.tcause_of_loss l on cl.cause_of_loss_sk = l.cause_of_loss_sk 
		LEFT JOIN edw_core.tsub_cause_of_loss s on cl.sub_cause_of_loss_sk =s.sub_cause_of_loss_sk 
		LEFT JOIN edw_core.tpolicy p on p.policy_no = cl.policy_no 
		INNER JOIN
		(
			SELECT
				cl.claim_sk,
				SUM(cl.loss_paid_amt + cl.expense_paid_amt + cl.adjusting_other_paid_amt) as TotalPayout,
				SUM(Case When claim_coverage_desc = 'Bodily Injury' then cl.loss_paid_amt+cl.expense_paid_amt End) as BodilyInjuryPayment,
				SUM(Case When claim_coverage_desc = 'Collision' then cl.loss_paid_amt+cl.expense_paid_amt End) as CollisionPayment,
				SUM(Case When claim_coverage_desc = 'Comprehensive' then cl.loss_paid_amt+cl.expense_paid_amt End) as ComprehensivePayment,
				SUM(Case When claim_coverage_desc = 'Glass' then cl.loss_paid_amt+cl.expense_paid_amt End) as GlassPayment,
				SUM(Case When claim_coverage_desc = 'Medical Payment' then cl.expense_paid_amt End) as MedicalExpensePayment,
				SUM(Case When claim_coverage_desc = 'Medical Payment' then cl.loss_paid_amt End) as MedicalPaymentPayment,
				SUM(Case When claim_coverage_desc in ('Property Protection (MI Only)', 'Property Damage') then cl.loss_paid_amt + cl.expense_paid_amt End) as PropertyDamagePayment,
				SUM(Case When claim_coverage_desc = 'No-Fault' then cl.loss_paid_amt + cl.expense_paid_amt End) as PersonalInjuryProtectionPayment,
				SUM(Case When claim_coverage_desc = 'Bodily Injury' then cl.loss_paid_amt + cl.expense_paid_amt End) as SpousalLiabilityPayment,
				SUM(Case When claim_coverage_desc IN ('Roadside Assistance','Towing') then cl.loss_paid_amt + cl.expense_paid_amt End) as TowingAndLaborPayment,
				SUM(Case When claim_coverage_desc = 'Uninsured Motorist' then cl.loss_paid_amt + cl.expense_paid_amt End) as UninsuredMotoristPayment,
				SUM(Case When claim_coverage_desc IN ('Uninsured / Underinsured Motorist','Underinsured Motorist')
					then cl.loss_paid_amt + cl.expense_paid_amt End) as UnderinsuredMotoristPayment,
				SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as ExcessLiabilityCoveragePayment,
				SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as UninsuredLiabilityPayment,
				SUM(CASE WHEN cl.claim_no NOT  LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as UnderinsuredLiabilityPayment,
				SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as ExcessLiabilityDOpayment,
				SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as EmploymentPracticesPaymentLiabilityPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpExcessLiabilityCoveragePayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpUninsuredLiabilityPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpUnderinsuredLiabilityPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpUninsuredMotoristPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpUnderinsuredMotoristPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpExcessLiabilityDOPayment,
				SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN cl.loss_paid_amt +  cl.expense_paid_amt ELSE NULL END) as GrpEmploymentPracticesLiabilityPayment
			FROM
				edw_core.tclaim cl
				INNER JOIN edw_core.tclaim_feature clf on cl.claim_sk = clf.claim_sk
			WHERE
				cl.product_sk in(3,4)
			GROUP BY cl.claim_sk
		) AS temp ON cl.claim_sk = temp.claim_sk

	MERGE edw_integration.claim_renewal_rating_auto_pel_api AS Target
	USING edw_temp.claim_renewal_rating_auto_pel_api_temp1 AS Source
	ON Source.[FileNumber] = Target.[FileNumber]
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT
		(
			IncidentDate,PolicyNumber,FileNumber,IncidentType,IncidentDescription,IncidentCode,TotalPayout,IncidentStatus,BodilyInjuryPayment,
			CollisionPayment,ComprehensivePayment,GlassPayment,MedicalExpensePayment,MedicalPaymentPayment,OtherPayment,PropertyDamagePayment,
			PersonalInjuryProtectionPayment,RentalReimbursementPayment,SpousalLiabilityPayment,TowingAndLaborPayment,UninsuredMotoristPayment,
			UnderinsuredMotoristPayment,ViolationPointClass,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
			IncidentDate,PolicyNumber,FileNumber,IncidentType,IncidentDescription,IncidentCode,TotalPayout,IncidentStatus,BodilyInjuryPayment,
			CollisionPayment,ComprehensivePayment,GlassPayment,MedicalExpensePayment,MedicalPaymentPayment,NULL,  -- OtherPayment
			PropertyDamagePayment,PersonalInjuryProtectionPayment,NULL , -- RentalReimbursementPayment
			SpousalLiabilityPayment,TowingAndLaborPayment,UninsuredMotoristPayment,
			UnderinsuredMotoristPayment,
			NULL, -- ViolationPointClass
			GETDATE(),GETDATE(),@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
			Target.IncidentDate	=	Source.IncidentDate,
			Target.PolicyNumber	=	Source.PolicyNumber,
			Target.FileNumber	=	Source.FileNumber,
			Target.IncidentType	=	Source.IncidentType,
			Target.IncidentDescription	=	Source.IncidentDescription,
			Target.IncidentCode	=	Source.IncidentCode,
			Target.TotalPayout	=	Source.TotalPayout,
			Target.IncidentStatus	=	Source.IncidentStatus,
			Target.BodilyInjuryPayment	=	Source.BodilyInjuryPayment,
			Target.CollisionPayment	=	Source.CollisionPayment,
			Target.ComprehensivePayment	=	Source.ComprehensivePayment,
			Target.GlassPayment	=	Source.GlassPayment,
			Target.MedicalExpensePayment	=	Source.MedicalExpensePayment,
			Target.MedicalPaymentPayment	=	Source.MedicalPaymentPayment,
			Target.OtherPayment	=	NULL,
			Target.PropertyDamagePayment	=	Source.PropertyDamagePayment,
			Target.PersonalInjuryProtectionPayment	=	Source.PersonalInjuryProtectionPayment,
			Target.RentalReimbursementPayment	=	NULL,
			Target.SpousalLiabilityPayment	=	Source.SpousalLiabilityPayment,
			Target.TowingAndLaborPayment	=	Source.TowingAndLaborPayment,
			Target.UninsuredMotoristPayment	=	Source.UninsuredMotoristPayment,
			Target.UnderinsuredMotoristPayment	=	Source.UnderinsuredMotoristPayment,
			Target.ViolationPointClass	=	NULL,
			Target.update_ts = GETDATE();
			
		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.claim_renewal_rating_auto_pel_api_temp1;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
	END CATCH
END