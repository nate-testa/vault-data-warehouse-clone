-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates claim diary data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/03/23		Yunus Mohammd				1. Created this procedure
-- 11/20/23		Yunus Mohammd				2. Added Throw
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_diary]

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

		DROP TABLE IF exists edw_temp.tclaim_diary_temp1;

		SELECT
			tc.claim_no,tc.claim_sk,
			CASE WHEN CHARINDEX('SUBCLAIM',UPPER(d.attach_to))>0 THEN
			SUBSTRING(d.attach_to,10,3) ELSE NULL END AS subclaim_seq_no
			,d.diary_type,
			d.diary_title,d.diary_content,
			CASE
				WHEN d.status=1 THEN 'Not completed'
				WHEN d.status=2 THEN 'Completed'
			END AS status_desc,
			CASE
				WHEN d.priority=10 THEN 'Low'
				WHEN d.priority=30 THEN 'Medium'
				WHEN d.priority=50 THEN 'High'
			END AS diary_priority,
			tpuc.REAL_NAME AS diary_created_by_nm,
			d.insert_time AS diary_created_ts,
			tpus.REAL_NAME AS assign_to,
			CAST(d.due_date AS DATE) AS due_dt,
			3 AS source_system_sk,
			d.update_time
		INTO edw_temp.tclaim_diary_temp1
		FROM
		edw_stage.t_pub_diary d
		INNER JOIN edw_stage.t_clm_case cc ON d.refer_no=cc.claim_no
		INNER JOIN edw_core.tclaim tc ON tc.claim_no=cc.claim_no
		LEFT JOIN edw_stage.t_pub_user tpuc ON tpuc.[user_id] = d.insert_by
		LEFT JOIN edw_stage.t_pub_user tpus ON tpus.[user_id] = d.assign_to
		WHERE
			d.update_time >@last_source_extract_ts;
		
	MERGE edw_core.tclaim_diary AS Target
	USING edw_temp.tclaim_diary_temp1 AS Source
	ON Target.claim_no=Source.claim_no AND
		ISNULL(Target.subclaim_seq_no,-111) = ISNULL(Source.subclaim_seq_no,-111)			
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_no,claim_sk,subclaim_seq_no,diary_type,diary_title,diary_content,status_desc,
			diary_priority,diary_created_by_nm,diary_created_ts,assign_to,due_dt,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
		claim_no,claim_sk,subclaim_seq_no,diary_type,diary_title,diary_content,status_desc,
		diary_priority,diary_created_by_nm,diary_created_ts,assign_to,due_dt,
		source_system_sk,GETDATE(),GETDATE(),@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.diary_type=Source.diary_type,
		Target.diary_title=Source.diary_title,
		Target.diary_content=Source.diary_content,
		Target.status_desc=Source.status_desc,
		Target.diary_priority=Source.diary_priority,
		Target.diary_created_by_nm=Source.diary_created_by_nm,
		Target.assign_to=Source.assign_to,
		Target.due_dt=Source.due_dt,
		Target.update_ts=GETDATE();

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_time) FROM edw_temp.tclaim_diary_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_diary_temp1
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

