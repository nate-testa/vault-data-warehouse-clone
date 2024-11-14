-- ==================================================================================================================================
-- Description: This procedures updates Thome_coverage last_inspection_dt
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 10/05/23		Architha Gudimalla		    1. VI34653 |AD7631 - Created this procedure
-- ================================================================================================================================== 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_thome_coverage_update_inspection_dt]

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
		DECLARE @CU DATETIME=GETDATE()
		
        -- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 
		
		-------------------------------------------------------------------------------------------------------------------------------------

		DROP TABLE IF exists edw_temp.thome_cov_upd_inspection_dt; 

		--get all inspection records from vendor reports
		select  policynumber, cast(effectivedate as date) effectivedate, max(cast(value as date)) inspection_dt 
		into   	edw_temp.thome_cov_upd_inspection_dt
		from 	edw_stage.tvendor_report_field_data
		where 	source = 'LC360' 
		and 	field_name = 'Summary - Inspection Date'
		and 	TransactionStatus = 'Complete'
		and 	CreatedDate > @last_source_extract_ts
		group by  policynumber, cast(effectivedate as date)

		DROP TABLE IF exists edw_temp.thome_cov_upd_inspection_dt_final; 

		--use records created above and join to tpolicy for the current term
		select a.*, pol.original_policy_no , pol.term_no
		into  edw_temp.thome_cov_upd_inspection_dt_final
		from   edw_temp.thome_cov_upd_inspection_dt a
		inner join edw_core.tpolicy pol on a.policynumber = pol.policy_no

		--use records created above and join to tpolicy for the future term by joining on original_policy_no and term
		insert into  edw_temp.thome_cov_upd_inspection_dt_final
		select	 pol.policy_no, pol.effective_dt, max(a.inspection_dt) inspection_dt, pol.original_policy_no, pol.term_no 
		from	 edw_core.tpolicy pol 
		inner join edw_temp.thome_cov_upd_inspection_dt_final a  on a.original_policy_no = pol.original_policy_no and pol.term_no > a.term_no
		where  	pol.policy_no not in (select policynumber from edw_temp.thome_cov_upd_inspection_dt_final) 
		group by pol.policy_no, pol.effective_dt,  pol.original_policy_no, pol.term_no 
		order by 1; 

		update 		cov
		set 		cov.last_inspection_dt = a.inspection_dt
		from 		edw_core.thome_coverage cov
		inner join 	edw_temp.thome_cov_upd_inspection_dt_final a on cov.policy_no = a.policynumber  ;

		DROP TABLE IF exists edw_temp.thome_cov_upd_inspection_dt_final; 
		DROP TABLE IF exists edw_temp.thome_cov_upd_inspection_dt; 
		
		-------------------------------------------------------------------------------------------------------------------------------------

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT dateadd(d,-1,MAX(CreatedDate)) 
												  FROM edw_stage.tvendor_report_field_data
												  where 	source = 'LC360' 
												  and 	field_name = 'Summary - Inspection Date'
												  and 	TransactionStatus = 'Complete'
												 ),@last_source_extract_ts); 
		
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

