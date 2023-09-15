/****** Object:  StoredProcedure [edw_core].[sp_tclaim_feature]    Script Date: 15-09-2023 20:40:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts and updates claim feature data

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
		tcl.claim_sk,tcase.claim_no,c.SUBCLAIM_TYPE AS subclaim_type_nm, c.seq_no AS subclaim_seq_no,
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
		e.loss_status AS claim_feature_status,tic.internal_coverage_sk as aslob_sk, g.real_name AS claim_adjuster_nm,tcpi2.insured_name AS risk_item,
		3 AS source_system_sk
		INTO edw_temp.tclaim_feature_temp1
		FROM
		edw_stage.t_clm_case tcase
		INNER JOIN edw_core.tclaim tcl ON tcase.claim_no=tcl.claim_no
		INNER JOIN edw_stage.t_clm_object AS c ON c.case_id = tcase.CASE_ID
		INNER JOIN edw_stage.t_clm_item AS e ON c.[object_id] = e.[object_id]
		LEFT JOIN edw_stage.t_clm_pol_insured tcpi2 ON c.insured_id=tcpi2.insured_id
		LEFT JOIN edw_stage.t_pub_user g ON c.OWNER_ID = g.[USER_ID]
		LEFT JOIN edw_core.tproduct prd ON prd.product_cd=tcase.product_code
		-- LEFT JOIN edw_core.taslob asl ON TRIM(asl.coverage_cd)=TRIM(e.coverage_name) AND 
		LEFT  JOIN edw_core.tinternal_coverage tic on tic.aslob_cd =TRIM(CAST( e.coverage_name AS VARCHAR(MAX)))
			and
			CASE 
			WHEN tic.product_cd='AU' THEN '2020201'
			WHEN tic.product_cd='LUX' THEN '2020101'
			WHEN tic.product_cd='PEL Liability' THEN '2020301'
			WHEN tic.product_cd='HO' THEN '2020001'
			END =e.product_code
		LEFT JOIN edw_core.tclaim_feature tcf ON tcf.claim_no=tcase.claim_no AND 
		tcf.subclaim_seq_no=c.seq_no AND tcf.claim_coverage_cd=e.coverage_code
		WHERE
			tcf.claim_feature_sk IS NULL

	MERGE edw_core.tclaim_feature  AS Target
	USING edw_temp.tclaim_feature_temp1 AS Source
	ON Source.claim_no=Target.claim_no
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
		claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
		claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
		litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
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
		Target.claim_adjuster_nm=Source.claim_adjuster_nm,
		Target.risk_item=Source.risk_item,
		Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		-- commented as we are not doing incremental insert
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tclaim_temp1),@last_source_extract_ts)
		-- EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_temp1
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
