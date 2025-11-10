-- ==========================================================================================================================================
-- Description: This procedures updates policy_status and latest_term_in for nfp policies
-----------------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						        |	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------
-- 11/05/25             Yunus Mohammed		    1. Created this procedure to update policy_status and latest_term_in
-- ========================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_update_nfp]

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
		
        update edw_core.tpolicy
        set policy_status = 'Active'
        where product_cd = 'GRPEL'; 
 
        update edw_core.tpolicy  
        set policy_status = 'Cancelled' 
        from edw_core.tpolicy
        where cancellation_effective_dt <= getdate()
        and product_cd = 'GRPEL';
        
        update edw_core.tpolicy
        set policy_status = 'Expired'
        where expiration_dt <= cast(getdate() as date)
        and product_cd = 'GRPEL'; 

        update edw_core.tpolicy
                set latest_term_in = 'N'
        where product_cd = 'GRPEL'; 
        
        update pol
                set latest_term_in = 'Y'
                from edw_core.tpolicy pol      
        where effective_dt = (select max(effective_dt) from edw_core.tpolicy pol1 where pol.original_policy_no = pol1.original_policy_no)
            and product_cd = 'GRPEL';

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
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
