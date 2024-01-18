/****** Object:  StoredProcedure [edw_core].[sp_ttask]    Script Date: 1/17/2024 12:00:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures inserts task data
------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------
-- 01/16/24		Hernando Gonzalez Garcia		1. Created this procedure 
-- 01/17/24		Architha Gudimalla				2. Fixed errors after first run  
-- ============================================================================================================= 

CREATE or ALTER   PROCEDURE [edw_core].[sp_ttask]

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
        DROP TABLE IF EXISTS edw_temp.[ttask_temp1]
        SELECT 
            acc.PolicyNumber
            ,acc.EffectiveDate
            ,acctr.TransactionEffectiveDate
            ,acctr.number
            --,acctr.PolicyChangeNumber
            ,wt.TaskName
            ,wf.name as [WorkFlow]
            ,wfs.name as [Step]
            ,cu.[name] CreatedBy
            ,au.[name] AssignedTo
            ,fu.[name] Completedby
            ,wt.WorkTaskState as task_status
            ,wt.Priority
            ,wt.IsClosed
            ,wfs.DueDays due_days
            ,wt.CreatedDate
            ,wt.DueDate
            ,wt.FinishedDate as CompletedDate
            ,DATEDIFF(mi, wt.CreatedDate, wt.FinishedDate) task_completion_time_in_minutes
            ,wt.UpdatedDate
            ,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] 
            ,getdate() create_ts
            ,getdate() update_ts
            ,@etl_audit_sk as etl_audit_sk
        INTO edw_temp.[ttask_temp1] 
        from edw_stage.account acc
        inner join edw_stage.[WorkTask] wt on acc.id = wt.accountid
        left join edw_stage.AccountTransaction acctr on wt.accounttransactionid = acctr.Id
        left join edw_stage.[User] au on wt.AssignedUserId = au.Id
        left join edw_stage.[User] cu on wt.CreatedById = cu.Id
        left join edw_stage.[User] fu on wt.FinishedById = fu.Id
        left join edw_stage.[User] u on wt.AssignedUserId = u.Id
        left join edw_stage.Workflow wf on wt.WorkflowId = wf.id
        left join edw_stage.WorkflowStep wfs on wt.WorkflowStepId = wfs.id        
		WHERE GREATEST(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts
		--and acc.policynumber is not null

        INSERT INTO [edw_core].[ttask](
            	[policy_no]
	            ,[effective_dt]
	            ,[transaction_effective_dt]
	            ,[transaction_seq_no]
	            ,[task_nm]
	            ,[workflow_nm]
	            ,[workflow_step_nm]
	            ,[created_by_nm]
	            ,[assigned_to_nm]
	            ,[completed_by_nm]
	            ,[task_status]
	            ,[priority]
	            ,[is_closed_in]
	            ,[due_days]
	            ,[created_dt]
	            ,[due_dt]
	            ,[completed_dt]
            	,task_completion_time_in_minutes 
	            ,[updated_dt]
	            ,[source_system_sk]
	            ,[create_ts]
	            ,[update_ts]
	            ,[etl_audit_sk]
        )
        SELECT 	PolicyNumber, EffectiveDate, TransactionEffectiveDate, number, 
				TaskName, [WorkFlow], [Step], CreatedBy, AssignedTo, Completedby, task_status, 
				Priority, IsClosed, due_days, CreatedDate, DueDate, CompletedDate, task_completion_time_in_minutes, UpdatedDate, 
				[source_system_sk], create_ts, update_ts, etl_audit_sk
        FROM edw_temp.[ttask_temp1] 

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.CreatedDate,t1.UpdatedDate)) FROM edw_temp.[ttask_temp1] t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.[ttask_temp1]
		
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