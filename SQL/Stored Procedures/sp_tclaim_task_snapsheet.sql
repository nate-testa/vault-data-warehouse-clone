SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ======================================================================================================== 
-- Description: This procedures inserts and updates claim data
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/29/2024		Alberto Almario				1. Created this procedure - AD7391
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_task_snapsheet]

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


		DROP TABLE IF exists edw_temp.tclaim_task_snapsheet_temp1;
		
		
		SELECT 
			c.claim_number AS claim_no,
			tc.claim_sk AS claim_sk,
			NULL AS claim_feature_sk,
			t.exposure_id AS exposure_sk,
			t.status AS task_status,
			t.priority AS task_priority,
			t.note AS task_note,
			t.task_type_name AS task_type_nm,
			t.task_category_name AS task_category_nm,
			t.task_file_type AS task_file_type_nm,
			u1.name AS created_by_nm,
			u2.name AS completed_by_nm,
			u3.name AS assigned_to_nm,
			u4.name AS assigned_by_nm,
			u5.name AS first_assigned_by_nm,
			t.assigned_at AS assigned_at_ts,
			t.effective_at AS effective_at_ts,
			t.created_at AS created_at_ts,
			t.updated_at AS updated_at_ts,
			t.completed_at AS completed_at_ts,
			t.first_assigned_at AS first_assigned_at_ts,
			5 AS source_system_sk
		INTO edw_temp.tclaim_task_snapsheet_temp1
		FROM edw_stage_snapsheet.tasks as t
		INNER JOIN edw_stage_snapsheet.claims as c ON c.id = t.claim_id
		INNER JOIN edw_core.tclaim as tc ON tc.claim_no = c.claim_number
		LEFT JOIN edw_stage_snapsheet.users as u1 ON u1.id = t.created_by_user_id
		LEFT JOIN edw_stage_snapsheet.users as u2 ON u2.id = t.completed_by_user_id
		LEFT JOIN edw_stage_snapsheet.users as u3 ON u3.id = t.assigned_to_user_id
		LEFT JOIN edw_stage_snapsheet.users as u4 ON u4.id = t.assigned_by_user_id
		LEFT JOIN edw_stage_snapsheet.users as u5 ON u5.id = t.first_assigned_by_user_id
		WHERE GREATEST(t.created_at,t.updated_at) > @last_source_extract_ts
		;
		
		
		-- MERGE edw_core.tclaim_task_snapsheet AS Target
		-- USING edw_temp.tclaim_task_snapsheet_temp1 AS Source
		-- 	ON Source.claim_no = Target.claim_no
		-- 	AND Source.task_status = Target.task_status
		-- 	AND Source.effective_at_ts = Target.effective_at_ts
		-- 	AND Source.task_note = Target.task_note
		-- -- For Inserts
		-- WHEN NOT MATCHED BY Target THEN
		-- INSERT (
		-- 		claim_no,
		-- 		claim_sk,
		-- 		claim_feature_sk,
		-- 		exposure_sk,
		-- 		task_status,
		-- 		task_priority,
		-- 		task_note,
		-- 		task_type_nm,
		-- 		task_category_nm,
		-- 		task_file_type_nm,
		-- 		created_by_nm,
		-- 		completed_by_nm,
		-- 		assigned_to_nm,
		-- 		assigned_by_nm,
		-- 		first_assigned_by_nm,
		-- 		assigned_at_ts,
		-- 		effective_at_ts,
		-- 		created_at_ts,
		-- 		updated_at_ts,
		-- 		completed_at_ts,
		-- 		first_assigned_at_ts
		-- 		source_system_sk,
		-- 		create_ts,
		-- 		update_ts,
		-- 		etl_audit_sk
		-- 	)
		-- VALUES (
		-- 		claim_no,
		-- 		claim_sk,
		-- 		claim_feature_sk,
		-- 		exposure_sk,
		-- 		task_status,
		-- 		task_priority,
		-- 		task_note,
		-- 		task_type_nm,
		-- 		task_category_nm,
		-- 		task_file_type_nm,
		-- 		created_by_nm,
		-- 		completed_by_nm,
		-- 		assigned_to_nm,
		-- 		assigned_by_nm,
		-- 		first_assigned_by_nm,
		-- 		assigned_at_ts,
		-- 		effective_at_ts,
		-- 		created_at_ts,
		-- 		updated_at_ts,
		-- 		completed_at_ts,
		-- 		first_assigned_at_ts,
		-- 		source_system_sk,
		-- 		GETDATE() AS create_ts,
		-- 		GETDATE() AS update_ts,
		-- 		@etl_audit_sk AS etl_audit_sk
		-- 	)
		-- -- For Updates
		-- WHEN MATCHED THEN UPDATE 
		-- SET
		-- 	Target.claim_no = Source.claim_no
		-- 	Target.claim_sk = Source.claim_sk
		-- 	Target.claim_feature_sk = Source.claim_feature_sk
		-- 	Target.exposure_sk = Source.exposure_sk
		-- 	Target.task_status = Source.task_status
		-- 	Target.task_priority = Source.task_priority
		-- 	Target.task_note = Source.task_note
		-- 	Target.task_type_nm = Source.task_type_nm
		-- 	Target.task_category_nm = Source.task_category_nm
		-- 	Target.task_file_type_nm = Source.task_file_type_nm
		-- 	Target.created_by_nm = Source.created_by_nm
		-- 	Target.completed_by_nm = Source.completed_by_nm
		-- 	Target.assigned_to_nm = Source.assigned_to_nm
		-- 	Target.assigned_by_nm = Source.assigned_by_nm
		-- 	Target.first_assigned_by_nm = Source.first_assigned_by_nm
		-- 	Target.assigned_at_ts = Source.assigned_at_ts
		-- 	Target.effective_at_ts = Source.effective_at_ts
		-- 	Target.created_at_ts = Source.created_at_ts
		-- 	Target.updated_at_ts = Source.updated_at_ts
		-- 	Target.completed_at_ts = Source.completed_at_ts
		-- 	Target.first_assigned_at_ts = Source.first_assigned_at_ts
		-- 	Target.source_system_sk = Source.source_system_sk
		-- 	Target.update_ts = GETDATE()
		-- 	;

			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(updated_at_ts) FROM edw_temp.tclaim_task_snapsheet_temp1),@last_source_extract_ts)
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

			
			-- Drop temp table
			DROP TABLE IF EXISTS edw_temp.tclaim_task_snapsheet_temp1

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