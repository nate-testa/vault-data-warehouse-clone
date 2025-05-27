-- ======================================================================================================== 
-- Description: This procedures inserts and updates claim data
-----------------------------------------------------------------------------------------------------------
-- Change date				|Author									|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/29/2024			  Alberto Almario				  1. Created this procedure - AD7391
-- 01/14/2025			  Yunus Mohammed			2. Updated Merge statement join
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
			t.id AS task_id,
			t.task_type_name AS task_type_nm,
			t.status AS task_status,
			t.priority AS task_priority,
			t.note AS task_note,
			t.task_category_name AS task_category_nm,
			t.task_file_type AS task_file_type_nm,
			u1.name AS task_created_by_nm,
			t.created_at AS task_created_ts,
			u2.name AS task_completed_by_nm,
			t.completed_at AS task_completed_ts,
			u3.name AS task_assigned_to_nm,
			u4.name AS task_assigned_by_nm,
			t.assigned_at AS task_assigned_ts,
			t.effective_at AS task_effective_ts,
			t.updated_at AS task_updated_ts,
			5 AS source_system_sk
		INTO edw_temp.tclaim_task_snapsheet_temp1
		FROM edw_stage_snapsheet.tasks as t
		INNER JOIN edw_stage_snapsheet.claims as c ON c.id = t.claim_id
		INNER JOIN edw_core.tclaim as tc ON tc.claim_no = c.claim_number
		LEFT JOIN edw_stage_snapsheet.users as u1 ON u1.id = t.created_by_user_id
		LEFT JOIN edw_stage_snapsheet.users as u2 ON u2.id = t.completed_by_user_id
		LEFT JOIN edw_stage_snapsheet.users as u3 ON u3.id = t.assigned_to_user_id
		LEFT JOIN edw_stage_snapsheet.users as u4 ON u4.id = t.assigned_by_user_id
		WHERE GREATEST(t.created_at,t.updated_at) > @last_source_extract_ts;
		
		
		MERGE edw_core.tclaim_task AS Target
		USING edw_temp.tclaim_task_snapsheet_temp1 AS Source
			ON Source.claim_no = Target.claim_no
			and Source.task_id = Target.task_id
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				claim_no
				,claim_sk
				,task_id
				,task_type_nm
				,task_status
				,task_priority
				,task_note
				,task_category_nm
				,task_file_type_nm
				,task_created_by_nm
				,task_created_ts
				,task_completed_by_nm
				,task_completed_ts
				,task_assigned_to_nm
				,task_assigned_by_nm
				,task_assigned_ts
				,task_effective_ts
				,task_updated_ts
				,source_system_sk
				,create_ts
				,update_ts
				,etl_audit_sk
			)
		VALUES (
				claim_no
				,claim_sk
				,task_id
				,task_type_nm
				,task_status
				,task_priority
				,task_note
				,task_category_nm
				,task_file_type_nm
				,task_created_by_nm
				,task_created_ts
				,task_completed_by_nm
				,task_completed_ts
				,task_assigned_to_nm
				,task_assigned_by_nm
				,task_assigned_ts
				,task_effective_ts
				,task_updated_ts
				,source_system_sk
				,GETDATE()
				,GETDATE()
				,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			Target.claim_sk = Source.claim_sk
			,Target.task_id = Source.task_id
			,Target.task_type_nm = Source.task_type_nm
			,Target.task_status = Source.task_status
			,Target.task_priority = Source.task_priority
			,Target.task_note = Source.task_note
			,Target.task_category_nm = Source.task_category_nm
			,Target.task_file_type_nm = Source.task_file_type_nm
			,Target.task_created_by_nm = Source.task_created_by_nm
			,Target.task_created_ts = Source.task_created_ts
			,Target.task_completed_by_nm = Source.task_completed_by_nm
			,Target.task_completed_ts = Source.task_completed_ts
			,Target.task_assigned_to_nm = Source.task_assigned_to_nm
			,Target.task_assigned_by_nm = Source.task_assigned_by_nm
			,Target.task_assigned_ts = Source.task_assigned_ts
			,Target.task_effective_ts = Source.task_effective_ts
			,Target.task_updated_ts = Source.task_updated_ts
			,Target.source_system_sk = Source.source_system_sk
			,Target.update_ts = GETDATE()
			;

			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(task_created_ts,task_updated_ts)) FROM edw_temp.tclaim_task_snapsheet_temp1),@last_source_extract_ts)
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