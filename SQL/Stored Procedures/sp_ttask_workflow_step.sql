SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================================================================
-- Description: This procedures inserts task workflow step names 
------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------
-- 02/06/24		Architha Gudimalla				1. Created this procedure   
-- 02/07/24		Architha Gudimalla				2. Added update on task_workflow_step_category_nm
-- 02/14/24		Architha Gudimalla				3. Added 2 updates on task_workflow_step_category_nm
-- ============================================================================================================= 

CREATE or ALTER   PROCEDURE edw_core.sp_ttask_workflow_step

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
        DROP TABLE IF EXISTS edw_temp.ttask_workflow_step_temp1
        SELECT 	  wf.name task_workflow_nm
				 ,wfs.name as task_workflow_step_nm 
				 , null as task_workflow_step_category_nm  
				, wfs.CreatedDate
				, wfs.UpdatedDate
        INTO 	edw_temp.ttask_workflow_step_temp1 
        from  edw_stage.Workflow wf 
        inner join edw_stage.WorkflowStep wfs on wf.id = wfs.WorkflowId 
		WHERE 	GREATEST(wfs.CreatedDate,wf.UpdatedDate)>@last_source_extract_ts  

		MERGE edw_core.ttask_workflow_step AS Target
		USING 
		(	
			SELECT 	task_workflow_nm, task_workflow_step_nm, task_workflow_step_category_nm
        	FROM edw_temp.ttask_workflow_step_temp1 
		)  AS Source
		ON Source.task_workflow_nm = Target.task_workflow_nm and Source.task_workflow_step_nm = Target.task_workflow_step_nm 
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				task_workflow_nm,
				task_workflow_step_nm,
				task_workflow_step_category_nm,
				create_ts,
				update_ts 
			)
		VALUES (Source.task_workflow_nm, source.task_workflow_step_nm, Source.task_workflow_step_category_nm, getdate(), getdate() )
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.update_ts					= getdate(); 

		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Admitted Endorsement Bound & Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Admitted Endorsement Declined';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Admitted Endorsement Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Admitted Endorsement Offered';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Non Premium Endorsement Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Premium Endorsement Bind Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Admitted Endorsement' and task_workflow_step_nm  =  'Premium Endorsement Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Admitted Renewal' and task_workflow_step_nm  =  'Admitted Renewal Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Admitted Renewal' and task_workflow_step_nm  =  'Admitted Renewal Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Admitted Renewal' and task_workflow_step_nm  =  'Bind Admitted Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Admitted Renewal' and task_workflow_step_nm  =  'Process Admitted Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Admitted Renewal' and task_workflow_step_nm  =  'Quote Admitted Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'Cancellation' and task_workflow_step_nm  =  'Cancellation Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'Cancellation' and task_workflow_step_nm  =  'Cancellation Request Rescinded';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'Cancellation' and task_workflow_step_nm  =  'Policy Canceled';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Claims' where task_workflow_nm = 'Claims' and task_workflow_step_nm  =  'Claim Risk Alert Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Endorsement Referral' and task_workflow_step_nm  =  'Endorsement Quote Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Endorsement Referral' and task_workflow_step_nm  =  'Referral Approved';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Endorsement Referral' and task_workflow_step_nm  =  'Referral Denied';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Endorsement Referral' and task_workflow_step_nm  =  'Referral Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Cancellation Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Claims' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Claims';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Endorsement Referral';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Endorsment';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'RMS' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Inspection has been cancelled';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'RMS' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Inspection Ordered on Cancelled Policy';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Manual Bind Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Manual Quote';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'New Business Referral';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'New York Change form requires stamping';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'Renewal Referral';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'RMS' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'RMS';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  'UW Inquiry';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'null' where task_workflow_nm = 'Legacy' and task_workflow_step_nm  =  '';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Binds' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'NB Bind Request Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'NB Bound & Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'NB Declined';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'NB Underwriting Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'Quote Declined';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'Quote Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'Quote Offered';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'Submit Dec & Diligent Effort to ELANY';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'New Business' where task_workflow_nm = 'New Business' and task_workflow_step_nm  =  'Upload ELANY Dec and Issue';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'New Business Follow Up' and task_workflow_step_nm  =  'NB Bind Requested';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'New Business Follow Up' and task_workflow_step_nm  =  'NB Bound & Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'New Business Follow Up' and task_workflow_step_nm  =  'New Business Follow Up';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'New Business Follow Up' and task_workflow_step_nm  =  'Quote Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'New Business Referral' and task_workflow_step_nm  =  'Quote Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'New Business Referral' and task_workflow_step_nm  =  'Referral Approved';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'New Business Referral' and task_workflow_step_nm  =  'Referral Denied';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'New Business Referral' and task_workflow_step_nm  =  'Referral Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non Premium Endorsement Bind Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non Premium Endorsement Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non-Admitted Endorsement Bound & Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non-Admitted Endorsement Declined';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non-Admitted Endorsement Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Non-Admitted Endorsement Offered';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Premium Endorsement Bind Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Premium Endorsement Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Submit Dec & Policy Change to ELANY';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'Non-Admitted Endorsement' and task_workflow_step_nm  =  'Upload ELANY Dec and Issue';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Binds' where task_workflow_nm = 'Non-Admitted Option (From Admitted)' and task_workflow_step_nm  =  'Non-Admitted Renewal Option Bind Request Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Non-Admitted Renewal Bind Request Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Non-Admitted Renewal Bound & Issued';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Non-Admitted Renewal Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Non-Admitted Renewal Offered';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Process Non-Admitted Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Quote Non-Admitted Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Submit Dec to ELANY';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Non-Admitted Renewal' and task_workflow_step_nm  =  'Upload ELANY Dec and Issue';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Non-Renewal' where task_workflow_nm = 'Non-Renewal' and task_workflow_step_nm  =  'Mail out Non-Renewal Notice';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Non-Renewal' where task_workflow_nm = 'Non-Renewal' and task_workflow_step_nm  =  'Non-Renewal Rescinded';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Non-Renewal' where task_workflow_nm = 'Non-Renewal' and task_workflow_step_nm  =  'Non-Renewed';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Non-Renewal' where task_workflow_nm = 'Non-Renewal' and task_workflow_step_nm  =  'Process Non-Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Bind Requested';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Bound';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Follow Up';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Option Bind Requested';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Option Bound';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Option Follow Up';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Renewal Follow Up' and task_workflow_step_nm  =  'Renewal Option Not Taken ';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Renewal Referral' and task_workflow_step_nm  =  'Referral Approved';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Renewal Referral' and task_workflow_step_nm  =  'Referral Denied';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Renewal Referral' and task_workflow_step_nm  =  'Referral Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Referral' where task_workflow_nm = 'Renewal Referral' and task_workflow_step_nm  =  'Renewal Quote Not Taken';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'Renewal Review' and task_workflow_step_nm  =  'Renewal Review';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'RMS' where task_workflow_nm = 'RMS Queue' and task_workflow_step_nm  =  'Inspection Ordered on Cancelled Policy';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'VC - Cancellation Queue' and task_workflow_step_nm  =  'Cancellation Request';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Cancellation' where task_workflow_nm = 'VC - Cancellation Queue' and task_workflow_step_nm  =  'Renewal';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'Acknowledgement of Applicant';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'Diligent Effort Affidavit';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'Diligent Effort Form';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'New Jersey Customer Affidavit';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'Statement of Diligent Effort';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Forms' where task_workflow_nm = 'VC - Diligent Effort Forms Queue' and task_workflow_step_nm  =  'Texas Diligent Effort';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'VC - Endorsement Queue' and task_workflow_step_nm  =  'Endorsement Referral';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Endorsement' where task_workflow_nm = 'VC - Endorsement Queue' and task_workflow_step_nm  =  'New York Change form requires stamping';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'General' where task_workflow_nm = 'VC - General Queue' and task_workflow_step_nm  =  'Vehicle Not Yet Registered';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'VC - Renewal Queue' and task_workflow_step_nm  =  'New York Dec requires stamping';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Renewal' where task_workflow_nm = 'VC - Renewal Queue' and task_workflow_step_nm  =  'Renewal Referral';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'Follow Ups' where task_workflow_nm = 'Anythng in the follow up status' and task_workflow_step_nm  =  '';
		--added below on 20240214
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'VRE to VES' where task_workflow_nm = 'VRE to VES' and task_workflow_step_nm  =  'Quote VRE to VES Option';
		update edw_core.ttask_workflow_step set task_workflow_step_category_nm  = 'VRE to VES' where task_workflow_nm = 'Non-Admitted Option (From Admitted)' and task_workflow_step_nm  =  'Non-Admitted Renewal Option Underwriting Review'; 

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.CreatedDate,t1.UpdatedDate)) FROM edw_temp.ttask_workflow_step_temp1 t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.ttask_workflow_step_temp1
		
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