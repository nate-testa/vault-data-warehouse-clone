-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates data for claim renewal rating for auto and pel
---------------------------------------------------------------------------------------------------
-- Change date		|Author										|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/15/2023		Yunus Mohammed				1. Created this procedure 
-- 03/11/2024		Yunus Mohammed				2. Logic corrected to calculate amount columns
-- 01/08/2025		Rushin Shah							 3. AD8990 - Added new columns
-- 01/10/2025		Rushin Shah							 4. Updated the coverage information to match snapsheet coverages
-- 01/14/2025		Sandeep Gundreddy			5. minor logic change to MedicalExpensePayment,MedicalPaymentPayment
-- 05/08/2025		Yunus Mohammed				6. AD9412 Added adjuster_name
-- 06/11/2025		Yunus Mohammed				7. AD-9744 Add Litigation Tag Indicator  (Litigation and LitigationComplete)
-- 10/09/2025		Yunus Mohammed				8. AD-10933 Added new columns and updated definition of other columns
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

		SELECT *
		INTO edw_temp.claim_renewal_rating_auto_pel_api_temp1
		from
		(
		SELECT
		ROW_NUMBER()OVER(PARTITION BY cl.claim_no ORDER BY TotalPayout DESC) as rn,
		cl.loss_dt as IncidentDate,
		cl.policy_no as PolicyNumber,
		cl.claim_no as FileNumber,
		l.cause_of_loss_desc as IncidentType,
		cl.loss_desc as IncidentDescription,
		NULL as IncidentCode,
		cl.claim_status as IncidentStatus,
		cl.first_party_driver_nm as FirstPartyDriverName,
		cl.fault_decision as FaultDecision,
		cl.responsible_party as ResponsibleParty,
		cl.at_fault_pct as AtFaultPercent,
		TotalPayout,BodilyInjuryPayment,CollisionPayment,
		ComprehensivePayment,GlassPayment,MedicalExpensePayment,MedicalPaymentPayment,
		PropertyDamagePayment,PersonalInjuryProtectionPayment,SpousalLiabilityPayment,
		TowingAndLaborPayment,UninsuredMotoristPayment,UnderinsuredMotoristPayment,
		clf.claim_adjuster_nm as AdjusterName,
		cl.first_party_driver_relationship_to_insured as FirstPartyDriverRelationshipToInsured,
		cl.litigation_in as Litigation, cl.litigation_complete_in as LitigationComplete,
		cl.large_loss_in as LargeLoss,cl.loss_location_desc  as IncidentDescription2
		FROM
		edw_core.tclaim cl
		LEFT JOIN edw_core.tcause_of_loss l on cl.cause_of_loss_sk = l.cause_of_loss_sk 
		LEFT JOIN edw_core.tpolicy p on p.policy_no = cl.policy_no 
		INNER JOIN
		(
		SELECT		
		cl.claim_sk,
		SUM(cl.expense_paid_amt + cl.subrogation_recovery_amt + cl.overpayment_recovery_amt + cl.loss_paid_amt) AS TotalIncurred,
		SUM(clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt) as TotalPayout,
		SUM(Case When clf.claim_coverage_desc = 'Combined Single Limits' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as BodilyInjuryPayment,
		SUM(Case When clf.claim_coverage_desc = 'Collision' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as CollisionPayment,
		SUM(Case When clf.claim_coverage_desc = 'Comprehensive' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as ComprehensivePayment,
		SUM(Case When clf.claim_coverage_desc = 'Full Glass' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as GlassPayment,
		SUM(Case When clf.claim_coverage_desc = 'Medical Payments' then clf.expense_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as MedicalExpensePayment,
		SUM(Case When clf.claim_coverage_desc = 'Medical Payments' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as MedicalPaymentPayment,
		SUM(Case When clf.claim_coverage_desc = ('PD Liability Limit') then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as PropertyDamagePayment,
		SUM(Case When clf.claim_coverage_desc = 'PIP' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as PersonalInjuryProtectionPayment,
		SUM(Case When clf.claim_coverage_desc = 'Combined Single Limits' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as SpousalLiabilityPayment,
		SUM(Case When clf.claim_coverage_desc IN ('Roadside Assistance') then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as TowingAndLaborPayment,
		SUM(Case When clf.claim_coverage_desc = 'Uninsured Motorist Liablity' then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as UninsuredMotoristPayment,
		SUM(Case When clf.claim_coverage_desc IN ('Uninsured / Underinsured Motorist','Underinsured Motorist')
			then clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt End) as UnderinsuredMotoristPayment, -- RS : This is not there
		SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as ExcessLiabilityCoveragePayment,
		SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as UninsuredLiabilityPayment,
		SUM(CASE WHEN cl.claim_no NOT  LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as UnderinsuredLiabilityPayment,
		SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as ExcessLiabilityDOpayment,
		SUM(CASE WHEN cl.claim_no NOT LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as EmploymentPracticesPaymentLiabilityPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpExcessLiabilityCoveragePayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpUninsuredLiabilityPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpUnderinsuredLiabilityPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpUninsuredMotoristPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpUnderinsuredMotoristPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpExcessLiabilityDOPayment,
		SUM(CASE WHEN cl.claim_no LIKE 'NFP%' THEN clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.overpayment_recovery_amt ELSE NULL END) as GrpEmploymentPracticesLiabilityPayment
		FROM
		edw_core.tclaim cl
		INNER JOIN edw_core.tclaim_feature clf on cl.claim_sk = clf.claim_sk
		WHERE
		cl.product_sk in(3,4)
		GROUP BY cl.claim_sk
		) AS temp ON cl.claim_sk = temp.claim_sk
		inner join edw_core.tclaim_feature clf on temp.claim_sk = clf.claim_sk
		) as a
		where
		rn = 1

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
			UnderinsuredMotoristPayment,ViolationPointClass,FirstPartyDriverName,FaultDecision,ResponsibleParty,AtFaultPercent,
			AdjusterName,FirstPartyDriverRelationshipToInsured,Litigation,LitigationComplete,LargeLoss,IncidentDescription2,
			create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
			IncidentDate,PolicyNumber,FileNumber,IncidentType,IncidentDescription,IncidentCode,TotalPayout,IncidentStatus,BodilyInjuryPayment,
			CollisionPayment,ComprehensivePayment,GlassPayment,MedicalExpensePayment,MedicalPaymentPayment,NULL,  -- OtherPayment
			PropertyDamagePayment,PersonalInjuryProtectionPayment,NULL , -- RentalReimbursementPayment
			SpousalLiabilityPayment,TowingAndLaborPayment,UninsuredMotoristPayment,	UnderinsuredMotoristPayment,
			NULL, -- ViolationPointClass
			FirstPartyDriverName,FaultDecision,ResponsibleParty,AtFaultPercent,AdjusterName,FirstPartyDriverRelationshipToInsured,
			Litigation,LitigationComplete,LargeLoss,IncidentDescription2,
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
			Target.FirstPartyDriverName = Source.FirstPartyDriverName,
			Target.FaultDecision = Source.FaultDecision,
			Target.ResponsibleParty = Source.ResponsibleParty,
			Target.AtFaultPercent = Source.AtFaultPercent,
			Target.AdjusterName = Source.AdjusterName,
			Target.FirstPartyDriverRelationshipToInsured = Source.FirstPartyDriverRelationshipToInsured,
			Target.Litigation = Source.Litigation,
			Target.LitigationComplete = Source.LitigationComplete,
			Target.LargeLoss = Source.LargeLoss,
			Target.IncidentDescription2 = Source.IncidentDescription2,
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
GO