/****** Object:  StoredProcedure edw_core.sp_ttask    Script Date: 1/17/2024 12:00:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures inserts task data
----------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
----------------------------------------------------------------------------------------------------------------------
-- 01/16/24		Hernando Gonzalez Garcia		1. Created this procedure 
-- 01/17/24		Architha Gudimalla				2. Fixed errors after first run  
-- 02/06/24		Architha Gudimalla				3. Added task_workflow_step_sk 
-- 02/07/24		Architha Gudimalla				4. Updated merge join
-- 02/23/24		Architha Gudimalla				5. Updated source query to Include rows where policy number is null
--												   Added customer id
-- 05/03/24		Architha Gudimalla				6. Added filter on ProductLine
-- 06/11/24		Architha Gudimalla				7. Added user_sk
-- ==================================================================================================================== 

CREATE or ALTER PROCEDURE edw_core.sp_ttask

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
        DROP TABLE IF EXISTS edw_temp.ttask_temp1
        SELECT 
            acc.PolicyNumber policy_no
            ,acc.EffectiveDate effective_dt
            ,acctr.TransactionEffectiveDate transaction_effective_dt
            ,acctr.number  transaction_seq_no
            ,wt.TaskName task_nm
            ,wf.name as workflow_nm
            ,wfs.name as workflow_step_nm
            ,cu.name created_by_nm
            ,au.name assigned_to_nm
            ,fu.name completed_by_nm
            ,tcu.user_sk created_by_sk
            ,tau.user_sk assigned_to_sk
            ,tfu.user_sk completed_by_sk
            ,wt.WorkTaskState as task_status
            ,wt.Priority task_priority
            ,wt.CreatedDate task_created_dt
            ,wt.DueDate task_due_dt
            ,wt.FinishedDate as task_completed_dt
            ,DATEDIFF(day, wt.CreatedDate, wt.FinishedDate) task_completion_time_in_days
            ,DATEDIFF(mi, wt.CreatedDate, wt.FinishedDate) task_completion_time_in_minutes
            ,wt.UpdatedDate task_updated_dt
            ,case when wt.IsClosed = 1 then 'Yes' else 'No' end task_closed_in
            ,wfs.DueDays task_due_days
			,wt.SuspenseUntilDate task_suspended_until_dt
			,wt.AbandonedReason task_abandoned_reason_desc
            ,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as source_system_sk 
            ,getdate() create_ts
            ,getdate() update_ts
            ,@etl_audit_sk as etl_audit_sk
			, twf.task_workflow_sk  
			, twfs.task_workflow_step_sk  
			, cust.customer_sk
        INTO edw_temp.ttask_temp1 
        from edw_stage.WorkTask wt
        left join edw_stage.account acc on acc.id = wt.accountid
		left join edw_stage.Product pr on acc.ProductId = pr.id
        left join edw_stage.AccountTransaction acctr on wt.accounttransactionid = acctr.Id
        left join edw_stage.[User] au on case when wt.AssignedUserId = '' then null else wt.AssignedUserId end = au.Id
        left join edw_stage.[User] cu on wt.CreatedById = cu.Id
        left join edw_stage.[User] fu on wt.FinishedById = fu.Id
        left join edw_stage.[User] u on wt.AssignedUserId = u.Id
        left join edw_core.[tUser] tcu on wt.CreatedById = tcu.user_id
        left join edw_core.[tUser] tfu on wt.FinishedById = tfu.user_id
        left join edw_core.[tUser] tau on wt.AssignedUserId = tau.user_id
        left join edw_stage.Workflow wf on wt.WorkflowId = wf.id
        left join edw_stage.WorkflowStep wfs on wt.WorkflowStepId = wfs.id 
        left join edw_core.ttask_workflow twf on wf.name = twf.task_workflow_nm 
        left join edw_core.ttask_workflow_step twfs on wfs.name = twfs.task_workflow_step_nm  and wf.name = twfs.task_workflow_nm  
        inner join edw_stage.[Insured] ins on ins.id = wt.InsuredId       
        left join edw_core.tcustomer cust on cust.customer_id = CAST(ins.referencecode AS VARCHAR(255)) 
		WHERE GREATEST(wt.CreatedDate,wt.UpdatedDate)>@last_source_extract_ts
		and pr.ProductLine = 'PersonalLines'
		--and acc.policynumber is not null
		;

		MERGE edw_core.ttask AS Target
		USING 
		(	
			 SELECT 	policy_no, effective_dt, transaction_effective_dt, transaction_seq_no, 
						task_nm, workflow_nm, workflow_step_nm, created_by_nm, assigned_to_nm, completed_by_nm, task_status, created_by_sk, assigned_to_sk, completed_by_sk,
						task_priority, task_created_dt, task_due_dt, task_completed_dt, 
						task_completion_time_in_days, task_completion_time_in_minutes, task_updated_dt, task_closed_in, 
						task_due_days, task_suspended_until_dt, task_abandoned_reason_desc, task_workflow_sk, task_workflow_step_sk, 
						source_system_sk, create_ts, update_ts, etl_audit_sk, customer_sk
				FROM edw_temp.ttask_temp1
		)  AS Source
		ON  isnull(Source.policy_no,'') = isnull(Target.policy_no,'') and isnull(Source.effective_dt,'') = isnull(Target.effective_dt,'') and isnull(Source.transaction_seq_no,0) = isnull(Target.transaction_seq_no ,0)
		and Source.task_nm = Target.task_nm and Source.workflow_nm = Target.workflow_nm and Source.workflow_step_nm = Target.workflow_step_nm 
		and Source.task_created_dt = Target.task_created_dt and Source.customer_sk = Target.customer_sk
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				policy_no,
				effective_dt,
				transaction_effective_dt,
				transaction_seq_no,  
				task_nm,
				workflow_nm,
				workflow_step_nm,
				created_by_nm,
				assigned_to_nm,
				completed_by_nm,   
				created_by_user_sk,
				assigned_to_user_sk,
				completed_by_user_sk,    
				task_status,
				task_priority,
				task_created_dt,    
				task_due_dt,    
				task_completed_dt,
				task_completion_time_in_days,
				task_completion_time_in_minutes,
				task_updated_dt,
				task_closed_in,   
				task_due_days, 
				task_suspended_until_dt,
				task_abandoned_reason_desc,
				task_workflow_sk,
				task_workflow_step_sk,
				source_system_sk,
				create_ts,
				update_ts,
				etl_audit_sk 
				, customer_sk
			)
		VALUES (Source.policy_no, Source.effective_dt, Source.transaction_effective_dt, Source.transaction_seq_no, 
						Source.task_nm, Source.workflow_nm, Source.workflow_step_nm, 
						Source.created_by_nm, Source.assigned_to_nm, Source.completed_by_nm, Source.created_by_sk, Source.assigned_to_sk, Source.completed_by_sk, Source.task_status, 
						Source.task_priority, Source.task_created_dt, Source.task_due_dt, Source.task_completed_dt, 
						Source.task_completion_time_in_days, Source.task_completion_time_in_minutes, Source.task_updated_dt, Source.task_closed_in, 
						Source.task_due_days, Source.task_suspended_until_dt, Source.task_abandoned_reason_desc, Source.task_workflow_sk, source.task_workflow_step_sk,
						Source.source_system_sk, Source.create_ts, Source.update_ts, Source.etl_audit_sk, source.customer_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.assigned_to_nm 					= Source.assigned_to_nm,
		Target.completed_by_nm 					= Source.completed_by_nm,
		Target.assigned_to_user_sk 				= Source.assigned_to_sk,
		Target.completed_by_user_sk 			= Source.completed_by_sk,
		Target.task_status 						= Source.task_status,
		Target.task_priority 					= Source.task_priority,
		Target.task_due_dt 						= Source.task_due_dt,
		Target.task_completed_dt 				= Source.task_completed_dt,
		Target.task_completion_time_in_days 	= Source.task_completion_time_in_days,
		Target.task_completion_time_in_minutes 	= Source.task_completion_time_in_minutes,
		Target.task_updated_dt 					= Source.task_updated_dt,
		Target.task_closed_in 					= Source.task_closed_in,
		Target.task_suspended_until_dt 			= Source.task_suspended_until_dt,
		Target.task_abandoned_reason_desc 		= Source.task_abandoned_reason_desc,
		Target.task_workflow_sk 				= Source.task_workflow_sk,
		Target.task_workflow_step_sk 			= Source.task_workflow_step_sk
		; 

        /*INSERT INTO edw_core.ttask(
            	policy_no,
				effective_dt,
				transaction_effective_dt,
				transaction_seq_no,  
				task_nm,
				workflow_nm,
				workflow_step_nm,
				created_by_nm,
				assigned_to_nm,
				completed_by_nm,    
				task_status,
				task_priority,
				task_created_dt,    
				task_due_dt,    
				task_completed_dt,
				task_completion_time_in_days,
				task_completion_time_in_minutes,
				task_updated_dt,
				task_closed_in,   
				task_due_days, 
				task_suspended_until_dt,
				task_abandoned_reason_desc,
				task_workflow_sk,
				source_system_sk,
				create_ts,
				update_ts,
				etl_audit_sk
        )
        SELECT 	PolicyNumber, EffectiveDate, TransactionEffectiveDate, transaction_seq_no, 
				TaskName, WorkFlow, Step, CreatedBy, AssignedTo, Completedby, task_status, 
				Priority, CreatedDate, DueDate, CompletedDate, 
				task_completion_time_in_days, task_completion_time_in_minutes, UpdatedDate,IsClosed, 
				due_days, SuspenseUntilDate, AbandonedReason, task_workflow_sk,
				source_system_sk, create_ts, update_ts, etl_audit_sk
        FROM edw_temp.ttask_temp1 */
       

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.task_created_dt,t1.task_updated_dt)) FROM edw_temp.ttask_temp1 t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.ttask_temp1
		
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