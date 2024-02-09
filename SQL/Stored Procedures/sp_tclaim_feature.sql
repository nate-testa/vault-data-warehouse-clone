-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts and updates claim feature data
-----------------------------------------------------------------------------------------------------------
-- Change date 			|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 07/28/23				Yunus Mohammed				1. Created this procedure
-- 11/20/23				Yunus Mohammed				2. Added Throw
-- 01/31/24				Yunus Mohammed				3. Added new fields
-- 02/07/24				Yunus Mohammed				4. Converted 'Y' to 'Yes' and 'N' to 'No' for newly added fields.
-- ========================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_feature]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()

		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF EXISTS edw_temp.tclaim_feature_temp1

		SELECT
		tcl.claim_sk,tcase.claim_no,sct.subclaim_type_name AS subclaim_type_nm, c.seq_no AS subclaim_seq_no,
		e.coverage_code AS claim_coverage_cd,e.coverage_name AS claim_coverage_desc,c.claimant_name AS claimant_nm,
		CASE
			WHEN c.damage_severity=1 THEN 'Small'
			WHEN c.damage_severity=2 THEN 'Medium'
			WHEN c.damage_severity=3 THEN 'Large'
			ELSE c.damage_severity
		END AS damage_severity
		, CASE
			WHEN c.damage_type='I' THEN 'Bodily Injury'
			WHEN c.damage_type='O' THEN 'Other'
			WHEN c.damage_type='P' THEN 'Property'
			WHEN c.damage_type='V' THEN 'Vehicle'
			ELSE c.damage_type
		END AS damage_type	
		,c.is_subrogation AS possible_subrogation_in,c.is_salvage AS possible_salvage_in,
		c.total_loss_flag AS total_loss_in,c.litigation_flag AS litigation_in,prd.product_sk,
		e.loss_status AS claim_feature_status,
		asl.aslob_sk, 
		g.real_name AS claim_adjuster_nm,tcpi2.insured_name AS risk_item,
		CASE c.assignment_of_benefits_contractor
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS assignment_of_benefits_contractor_in,
		CASE c.public_adjuster
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS public_adjuster_in,
		CASE c.arbitration
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS arbitration_in,
		CASE c.mediation
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS mediation_in,
		CASE c.appraisal
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS appraisal_in,
		CASE c.alternative_dispute_resolution
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS alternative_dispute_resolution_in,
		CASE c.neutral_evaluation
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS neutral_evaluation_in,
		CASE c.settlement_conference
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS setllement_conference_in,
		CASE c.settlement_resolution
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
		END AS settlement_resolution_in,
		3 AS source_system_sk,
		CASE
			prd.product_cd
			WHEN 'HO' THEN thcov.home_coverage_sk
			WHEN 'LUX' THEN tccov.collection_coverage_sk
			WHEN 'PEL' THEN tpcov.pel_coverage_sk
			WHEN 'AU' THEN tacov.auto_policy_coverage_sk
		END AS coverage_sk ,
		CASE
			prd.product_cd
			WHEN 'HO' THEN thcov.home_location_sk
			WHEN 'LUX' THEN tccov.collection_location_sk
			WHEN 'PEL' THEN NULL
			WHEN 'AU' THEN taveh.auto_vehicle_sk
		END AS item_sk,
		CASE
			prd.product_cd
			WHEN 'HO' THEN NULL
			WHEN 'LUX' THEN NULL
			WHEN 'PEL' THEN NULL
			WHEN 'AU' THEN tavc.auto_vehicle_coverage_sk
		END AS vehicle_coverage_sk
		INTO edw_temp.tclaim_feature_temp1
		FROM
		edw_stage.t_clm_case tcase
		INNER JOIN edw_core.tclaim tcl ON tcase.claim_no=tcl.claim_no
		INNER JOIN edw_stage.t_clm_object AS c ON c.case_id = tcase.CASE_ID
		INNER JOIN edw_stage.t_clm_item AS e ON c.[object_id] = e.[object_id]
		LEFT JOIN edw_stage.t_clm_pol_insured tcpi2 ON c.insured_id=tcpi2.insured_id
		LEFT JOIN edw_stage.t_clm_subclaim_type sct ON c.subclaim_type = sct.subclaim_type_code
		LEFT JOIN edw_stage.t_pub_user g ON c.OWNER_ID = g.[USER_ID]		
		LEFT JOIN edw_core.tproduct prd ON prd.product_sk=tcl.product_sk

		LEFT JOIN edw_core.taslob asl ON TRIM(asl.coverage_cd)=CAST(e.coverage_name AS VARCHAR(MAX))
										AND CASE asl.product_cd
					WHEN 'Homeowners' THEN 'HO'
					WHEN 'Excess Liability' THEN 'PEL'
					WHEN 'Auto' THEN 'AU'
					WHEN 'Collections' THEN 'LUX'
					ELSE asl.product_cd
					END
			= prd.product_cd
		-- Home Coverage
        LEFT JOIN edw_core.thome_coverage thcov ON
		thcov.home_coverage_sk = (
                                SELECT TOP 1 home_coverage_sk
                                FROM
                                    edw_core.thome_coverage tcov1
                                WHERE
                                    tcov1.policy_no = tcl.policy_no
                                    AND tcl.loss_dt >= tcov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
                              )
		-- Collection Coverage
		LEFT JOIN edw_core.tcollection_coverage tccov ON
		tccov.collection_coverage_sk= (
                                SELECT TOP 1 collection_coverage_sk
                                FROM
                                    edw_core.tcollection_coverage tccov1
                                WHERE
                                    tccov1.policy_no = tcl.policy_no
                                    AND tcl.loss_dt > =tccov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
                              )
		-- PEL Coverage
		LEFT JOIN edw_core.tpel_coverage tpcov ON
		tpcov.pel_coverage_sk = (
                                SELECT TOP 1 pel_coverage_sk
                                FROM
                                    edw_core.tpel_coverage tpcov1
                                WHERE
                                    tpcov1.policy_no = tcl.policy_no
                                    AND tcl.loss_dt > =tpcov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
                              )
		-- Auto Coverage
		LEFT JOIN edw_core.tauto_policy_coverage tacov ON
		tacov.auto_policy_coverage_sk = (
                                SELECT TOP 1 auto_policy_coverage_sk
                                FROM
                                    edw_core.tauto_policy_coverage tacov1
                                WHERE
                                    tacov1.policy_no = tcl.policy_no
                                    AND tcl.loss_dt >= tacov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
                              )
		-- Auto Vehicle
		LEFT JOIN edw_core.tauto_vehicle taveh ON 
		taveh.policy_no = tcl.policy_no AND taveh.vehicle_vin = CAST(tcpi2.insured_name AS VARCHAR(MAX))	AND
		taveh.auto_vehicle_sk = (
									SELECT TOP 1 auto_vehicle_sk
									FROM
										edw_core.tauto_vehicle aveh1
									WHERE
										aveh1.policy_no = taveh.policy_no
										AND aveh1.vehicle_vin =  CAST(tcpi2.insured_name AS VARCHAR(MAX))
										AND tcl.loss_dt > = aveh1.effective_dt
									ORDER BY aveh1.effective_dt DESC
								)
		-- Auto Vehicle Coverage
		LEFT JOIN edw_core.tauto_vehicle_coverage tavc ON tavc.policy_no = tcl.policy_no and tavc.vehicle_no = taveh.vehicle_no
		AND
		tavc.auto_vehicle_coverage_sk= (
										SELECT TOP 1 auto_vehicle_coverage_sk
										FROM
										edw_core.tauto_vehicle_coverage tavc1
										WHERE
											tavc1.policy_no = tcl.policy_no
											AND tavc1.vehicle_no = taveh.vehicle_no
											AND tcl.loss_dt > = tavc1.transaction_effective_dt
										ORDER BY tavc1.transaction_seq_no DESC
									)
		LEFT JOIN edw_core.tclaim_feature tcf ON tcf.claim_no=tcase.claim_no AND 
		tcf.subclaim_seq_no=c.seq_no AND tcf.claim_coverage_cd=e.coverage_code



	MERGE edw_core.tclaim_feature  AS Target
	USING edw_temp.tclaim_feature_temp1 AS Source
	ON Source.claim_no=Target.claim_no
	AND Target.subclaim_seq_no=Source.subclaim_seq_no AND Target.claim_coverage_cd=Source.claim_coverage_cd
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			coverage_sk,item_sk,vehicle_coverage_sk,
			assignment_of_benefits_contractor_in,public_adjuster_in,arbitration_in,mediation_in,
			appraisal_in,alternative_dispute_resolution_in,neutral_evaluation_in,setllement_conference_in,settlement_resolution_in,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
		claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
		claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
		litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
		coverage_sk,item_sk,vehicle_coverage_sk,
		assignment_of_benefits_contractor_in,public_adjuster_in,arbitration_in,mediation_in,
		appraisal_in,alternative_dispute_resolution_in,neutral_evaluation_in,setllement_conference_in,settlement_resolution_in,
		3,@current_date,@current_date,@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.claim_sk=Source.claim_sk,
		Target.subclaim_type_nm=Source.subclaim_type_nm,
		Target.subclaim_seq_no=Source.subclaim_seq_no,
		Target.claimant_nm=Source.claimant_nm,
		Target.damage_severity=Source.damage_severity,
		Target.damage_type=Source.damage_type,
		Target.possible_subrogation_in=Source.possible_subrogation_in,
		Target.possible_salvage_in=Source.possible_salvage_in,
		Target.total_loss_in=Source.total_loss_in,
		Target.litigation_in=Source.litigation_in,
		Target.product_sk=Source.product_sk,
		Target.claim_feature_status=Source.claim_feature_status,
		Target.aslob_sk=Source.aslob_sk,
		Target.item_sk=Source.item_sk,
		Target.coverage_sk=Source.coverage_sk,
		Target.vehicle_coverage_sk=Source.vehicle_coverage_sk,
		Target.claim_adjuster_nm=Source.claim_adjuster_nm,
		Target.risk_item=Source.risk_item,
		Target.assignment_of_benefits_contractor_in=Source.assignment_of_benefits_contractor_in,
		Target.public_adjuster_in=Source.public_adjuster_in,
		Target.arbitration_in=Source.arbitration_in,
		Target.mediation_in=Source.mediation_in,
		Target.appraisal_in=Source.appraisal_in,
		Target.alternative_dispute_resolution_in=Source.alternative_dispute_resolution_in,
		Target.neutral_evaluation_in=Source.neutral_evaluation_in,
		Target.setllement_conference_in=Source.setllement_conference_in,
		Target.settlement_resolution_in=Source.settlement_resolution_in,
		Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_feature_temp1

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

