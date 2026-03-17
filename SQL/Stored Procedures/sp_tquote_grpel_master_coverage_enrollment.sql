-- ========================================================================================================================================
-- Description: This procedures inserts grpel master coverage enrollment
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 03/17/26			Yunus Mohammed				1. Created this procedure
-- ======================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_master_coverage_enrollment]

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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));
		
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_enrollment_temp1;
		
		select
            acc.PolicyNumber as grpel_master_quote_no,acc.EffectiveDate as effective_dt, acc.ExpirationDate as expiration_dt,
            u.[Name] as enrollment_created_user_nm,aes.CreatedDate as enrollment_created_ts,
            aes.EnrollmentInitialStartDate as enrollment_initial_start_dt,
            aes.EnrollmentPeriodByDays As  enrollment_period_in_days,
            aes.EnrollmentFrequency as enrollment_frequency,
            aes.OverrideEnrollmentToOpen as override_enrollment_to_open_in,
            CASE 
                WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                ELSE 4 --(Metal)
            END as [source_system_sk],
            aes.CreatedDate
        into edw_temp.tquote_grpel_master_coverage_enrollment_temp1
        from
            edw_stage.Account acc
            inner join edw_stage.AccountEnrollmentSnapshot aes on acc.Id= aes.AccountId
            left join edw_stage.[User] u on u.Id = aes.UserId
        where
            aes.CreatedDate > @last_source_extract_ts
		
		INSERT INTO [edw_core].[tquote_grpel_master_coverage_enrollment]
		(
            grpel_master_quote_no,effective_dt,expiration_dt,enrollment_created_user_nm,enrollment_created_ts,
            enrollment_initial_start_dt,enrollment_period_in_days,enrollment_frequency,override_enrollment_to_open_in,
            source_system_sk,create_ts,update_ts,etl_audit_sk
		)
        SELECT
            grpel_master_quote_no,effective_dt,expiration_dt,enrollment_created_user_nm,enrollment_created_ts,
            enrollment_initial_start_dt,enrollment_period_in_days,enrollment_frequency,override_enrollment_to_open_in,
            source_system_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
        FROM
            edw_temp.tquote_grpel_master_coverage_enrollment_temp1

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t.CreatedDate) FROM edw_temp.tquote_grpel_master_coverage_enrollment_temp1 t),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_enrollment_temp1;

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