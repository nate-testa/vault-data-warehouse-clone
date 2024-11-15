SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================
-- Description: This procedures updates Tquote_home_coverage
-----------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------
-- 11/13/23		Architha Gudimalla		    1. Created this procedure 
-- =============================================================================================================== 


CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_home_coverage_update_inspection_dt]

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
		
		----------------for non cancel rewrtes------------------------------------------------------------------------------------------------------------

		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt; 
		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_final; 

		--get all inspection records from vendor reports
		select  policynumber quote_no, cast(effectivedate as date) effectivedate, max(cast(value as date)) inspection_dt 
		into   	edw_temp.tquote_home_cov_upd_inspection_dt
		from 	edw_stage.tvendor_report_field_data
		where 	source = 'LC360' 
		and 	field_name = 'Summary - Inspection Date'
		and 	TransactionStatus = 'Complete'
		and 	CreatedDate > @last_source_extract_ts
		group by  policynumber, cast(effectivedate as date)

		--use records created above and join to tpolicy for the current term
		select a.*, q.original_policy_no , q.term_no
		into  edw_temp.tquote_home_cov_upd_inspection_dt_final
		from   edw_temp.tquote_home_cov_upd_inspection_dt a
		inner join edw_core.tquote q on a.quote_no = q.quote_no

		--use records created above and join to tpolicy for the future term by joining on original_policy_no and term
		insert into  edw_temp.tquote_home_cov_upd_inspection_dt_final
		select	 q.quote_no, q.effective_dt, max(a.inspection_dt) inspection_dt, q.original_policy_no, q.term_no 
		from	 edw_core.tquote q 
		inner join edw_temp.tquote_home_cov_upd_inspection_dt_final a  on a.original_policy_no = q.original_policy_no and q.term_no > a.term_no
		where  	q.quote_no not in (select quote_no from edw_temp.tquote_home_cov_upd_inspection_dt_final) 
		group by q.quote_no, q.effective_dt,  q.original_policy_no, q.term_no 
		order by 1; 

		update 		cov
		set 		cov.last_inspection_dt = a.inspection_dt
		from 		edw_core.tquote_home_coverage cov
		inner join 	edw_temp.tquote_home_cov_upd_inspection_dt_final a on cov.quote_no = a.quote_no  ;

		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_final; 
		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt; 
		
		----------------for cancel rewrtes---------------------------------------------------------------------------------------------------------------

		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_1; 
		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_2; 

		--pull all policies that were cancel rewritten
		select quote_no, effective_dt, max(last_inspection_dt) last_inspection_dt
		into edw_temp.tquote_home_cov_upd_inspection_dt_1
		from edw_core.tquote_home_coverage 
		where last_inspection_dt is not null
		and quote_no in (select prior_policy_no from edw_core.tquote)
		group by quote_no, effective_dt 
		
		--update last_inspection_dt for cancel rewritten policy using  the prior policy
		update cov
		set cov.last_inspection_dt = a.last_inspection_dt 
		from  edw_core.tquote_home_coverage cov
		inner join edw_core.tquote q on q.quote_no = cov.quote_no
		inner join edw_temp.tquote_home_cov_upd_inspection_dt_1 a on q.prior_policy_no = a.quote_no 
		where cov.last_inspection_dt is null 

		--pull subsequent terms of the cancel rewritten policy
		select	 q.quote_no, q.effective_dt, max(a.last_inspection_dt) last_inspection_dt 
		into edw_temp.tquote_home_cov_upd_inspection_dt_2
		from	 edw_core.tquote q 
		inner join (select cov.quote_no, cov.last_inspection_dt, q.original_policy_no, q.term_no
					from  edw_core.tquote_home_coverage cov
					inner join edw_core.tquote q on q.quote_no = cov.quote_no
					inner join edw_temp.tquote_home_cov_upd_inspection_dt_1 a on q.prior_policy_no = a.quote_no 
					) a  on a.original_policy_no = q.original_policy_no and q.term_no > a.term_no 
		group by q.quote_no, q.effective_dt  
		
		--update subsequent terms of the cancel rewritten policy
		update cov
		set cov.last_inspection_dt = a.last_inspection_dt 
		from  edw_core.tquote_home_coverage cov 
		inner join edw_temp.tquote_home_cov_upd_inspection_dt_2 a on cov.quote_no = a.quote_no 
		where cov.last_inspection_dt is null

		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_1; 
		DROP TABLE IF exists edw_temp.tquote_home_cov_upd_inspection_dt_2;  

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

GO
