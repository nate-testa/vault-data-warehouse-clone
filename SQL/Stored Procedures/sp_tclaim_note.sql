-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts and updates claim notes
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/03/23		Yunus Mohammd				1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_note]

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

		DROP TABLE IF exists edw_temp.tclaim_note_temp1;

		SELECT tc.claim_no,tc.claim_sk,c.seq_no AS subclaim_seq_no,n.note_content AS content_desc,
		CASE
		WHEN note_category=1 THEN 'Contact'
		WHEN note_category=2 THEN 'Correspondence'
		WHEN note_category=3 THEN 'Coverage'
		WHEN note_category=4 THEN 'File Note'
		WHEN note_category=5 THEN 'Litigation'
		WHEN note_category=6 THEN 'Payments'
		WHEN note_category=7 THEN 'Recoveries'
		WHEN note_category=8 THEN 'Reinsurance'
		WHEN note_category=9 THEN 'Reserves'
		WHEN note_category=10 THEN 'Supervisor Note'
		END AS category_nm,
		tpus.REAL_NAME AS send_message_to,
		tpuc.REAL_NAME AS note_created_by_nm,
		n.insert_time AS note_created_ts,
		CASE WHEN n.note_user_type='I' THEN 'Internal'
		WHEN n.note_user_type='E' THEN 'External'
		END AS user_type,
		n.note_overview AS overview_desc,
		n.insert_time,
		3 AS source_system_sk
		INTO edw_temp.tclaim_note_temp1
		FROM
		edw_stage.t_clm_note n
		INNER JOIN edw_stage.t_clm_case cc ON n.case_id=cc.case_id
		INNER JOIN edw_core.tclaim tc ON tc.claim_no=cc.claim_no
		LEFT JOIN edw_stage.t_clm_object AS c ON CAST(c.[object_id] AS VARCHAR(255))=
		CASE WHEN UPPER(n.NOTE_LEVEL)!='CLAIM' THEN n.note_level ELSE NULL END
		LEFT JOIN edw_stage.t_pub_user tpus ON tpus.[user_id] = n.send_message_to
		LEFT JOIN edw_stage.t_pub_user tpuc ON tpuc.[user_id] = n.insert_by		
		WHERE
		n.insert_time >@last_source_extract_ts;

		
		INSERT INTO edw_core.tclaim_note
		(claim_no,claim_sk,subclaim_seq_no,content_desc,category_nm,send_message_to,note_created_by_nm,note_created_ts,
		user_type,overview_desc,source_system_sk,create_ts,update_ts,etl_audit_sk)
		SELECT claim_no,claim_sk,subclaim_seq_no,content_desc,category_nm,send_message_to,note_created_by_nm,note_created_ts,
		user_type,overview_desc,source_system_sk,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tclaim_note_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(insert_time) FROM edw_temp.tclaim_note_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_note_temp1
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

