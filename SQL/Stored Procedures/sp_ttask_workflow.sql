SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================================================================
-- Description: This procedures inserts task workflow names 
------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------
-- 01/16/24		Architha Gudimalla				1. Created this procedure 
-- 01/17/24		Architha Gudimalla				2. Fixed errors after first run  
-- 02/06/24		Architha Gudimalla				3. Dropping the temp table  
-- ============================================================================================================= 

CREATE or ALTER   PROCEDURE edw_core.sp_ttask_workflow

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

        -- Create temp table with name as sp_tttask_temp and use it in 
        DROP TABLE IF EXISTS edw_temp.ttask_workflow_temp1
        SELECT 	  wf.name task_workflow_nm
				, null as task_workflow_category_nm  
				, CreatedDate
				, UpdatedDate
        INTO 	edw_temp.ttask_workflow_temp1 
		from 	edw_stage.Workflow wf      
		WHERE 	GREATEST(wf.CreatedDate,wf.UpdatedDate)>@last_source_extract_ts 

		MERGE edw_core.ttask_workflow AS Target
		USING 
		(	
			SELECT 	task_workflow_nm, task_workflow_category_nm
        	FROM edw_temp.ttask_workflow_temp1 
		)  AS Source
		ON Source.task_workflow_nm = Target.task_workflow_nm 
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				task_workflow_nm,
				task_workflow_category_nm,
				create_ts,
				update_ts 
			)
		VALUES (Source.task_workflow_nm, Source.task_workflow_category_nm, getdate(), getdate() )
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.update_ts					= getdate(); /*

		INSERT INTO edw_core.ttask_workflow(
				task_workflow_nm,
				task_workflow_category_nm,
				create_ts,
				update_ts 
			)
        SELECT 	task_workflow_nm, task_workflow_category_nm,  getdate(), getdate()
        	FROM edw_temp.ttask_workflow_temp1 ;*/

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.CreatedDate,t1.UpdatedDate)) FROM edw_temp.ttask_workflow_temp1 t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.ttask_workflow_temp1
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END