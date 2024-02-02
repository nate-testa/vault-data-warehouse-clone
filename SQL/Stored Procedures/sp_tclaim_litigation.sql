/****** Object:  StoredProcedure [edw_core].[sp_tclaim_litigation]    Script Date: 02-02-2024 21:01:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates claim litigation data
-----------------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 02/02/24			Yunus Mohammed				1. Created this procedure
-- ========================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_litigation]
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
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		
		DROP TABLE IF EXISTS edw_temp.tclaim_litigation_temp1
		select tcl.claim_no,
		obj.seq_no AS subclaim_seq_no,
		tcf.claim_sk,
		tcf.claim_feature_sk,
		lit.SUIT_NAME AS litigation_nm,
		lit.SUIT_TYPE  AS litigation_type,
		lit.SUIT_STATUS AS litigation_status ,
		lit.SUIT_STATUS_REMARK AS litigation_status_remark ,
		lit.SUIT_CASE_NUMBER AS litigation_case_no,
		lit.SUIT_OPEN_DATE AS litigation_open_dt,
		lit.DATE_OF_MEDIATION AS litigation_mediation_dt,
		lit.SUIT_CLOSE_DATE AS litigation_close_dt,
		lit.SUIT_LOCATION AS litigation_location,
		lit.LAWYER_NAME plaintiff_firm_nm,
		lit.LAWYER_TEL AS plaintiff_firm_phone_no,
		lit.LAWYER_EMAIL AS plaintiff_email,
		lit.AMOUNT_APEALED AS litigation_dispute_amt,
		lit.DEPOSITION_AMOUNT AS final_settlement_amt,
		lit.UPDATE_TIME
		INTO edw_temp.tclaim_litigation_temp1
		FROM
		edw_stage.t_clm_case tcase
		INNER JOIN edw_core.tclaim tcl ON tcase.claim_no=tcl.claim_no
		INNER JOIN edw_stage.t_clm_object AS obj ON tcase.case_id = obj.CASE_ID
		INNER JOIN edw_stage.t_clm_litigation lit ON lit.CASE_ID=obj.CASE_ID AND lit.[OBJECT_ID] = obj.[OBJECT_ID]
		LEFT JOIN edw_core.tclaim_feature tcf ON tcf.claim_no = tcl.claim_no and tcf.subclaim_seq_no = obj.seq_no
		WHERE
			lit.UPDATE_TIME > @last_source_extract_ts;

	MERGE edw_core.tclaim_litigation AS Target
	USING edw_temp.tclaim_litigation_temp1 AS Source
	ON Source.claim_feature_sk = Target.claim_feature_sk
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_no,subclaim_seq_no,claim_sk,claim_feature_sk,
			litigation_nm,litigation_type,litigation_status,litigation_status_remark,litigation_case_no,litigation_open_dt,
			litigation_mediation_dt,litigation_close_dt,litigation_location,plaintiff_firm_nm,plaintiff_firm_phone_no,
			plaintiff_email,litigation_dispute_amt,final_settlement_amt,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
			claim_no,subclaim_seq_no,claim_sk,claim_feature_sk,
			litigation_nm,litigation_type,litigation_status,litigation_status_remark,litigation_case_no,litigation_open_dt,
			litigation_mediation_dt,litigation_close_dt,litigation_location,plaintiff_firm_nm,plaintiff_firm_phone_no,
			plaintiff_email,litigation_dispute_amt,final_settlement_amt,
			3,@current_date,@current_date,@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.claim_no=	Source.claim_no,
		Target.subclaim_seq_no=	Source.subclaim_seq_no,
		Target.claim_sk=	Source.claim_sk,
		Target.claim_feature_sk=	Source.claim_feature_sk,
		Target.litigation_nm=	Source.litigation_nm,
		Target.litigation_type=	Source.litigation_type,
		Target.litigation_status=	Source.litigation_status,
		Target.litigation_status_remark=	Source.litigation_status_remark,
		Target.litigation_case_no=	Source.litigation_case_no,
		Target.litigation_open_dt=	Source.litigation_open_dt,
		Target.litigation_mediation_dt=	Source.litigation_mediation_dt,
		Target.litigation_close_dt=	Source.litigation_close_dt,
		Target.litigation_location=	Source.litigation_location,
		Target.plaintiff_firm_nm=	Source.plaintiff_firm_nm,
		Target.plaintiff_firm_phone_no=	Source.plaintiff_firm_phone_no,
		Target.plaintiff_email=	Source.plaintiff_email,
		Target.litigation_dispute_amt=	Source.litigation_dispute_amt,
		Target.final_settlement_amt=	Source.final_settlement_amt,
		Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UPDATE_TIME) FROM edw_temp.tclaim_litigation_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_litigation_temp1
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