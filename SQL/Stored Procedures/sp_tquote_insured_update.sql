-- =======================================================================================================================================================
-- Description: This procedures removes dups in tquote_insured
-------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
-------------------------------------------------------------------------------------------
-- 07/30/24		    Yunus Mohammed			    1. Created this procedure  
-- ========================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_insured_update]

AS 
BEGIN
    SET ANSI_WARNINGS OFF
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))   

        select quote_no, effective_dt, transaction_seq_no, primary_insured_in,row_count,has_email_in,
        case when quote_insured_sk is null then quote_insured_sk_without_null
        else quote_insured_sk end quote_insured_sk_final
        ,quote_insured_sk,quote_insured_sk_without_null
        into edw_temp.tquote_insured_update_temp1
        from
        (
        select quote_no, effective_dt, transaction_seq_no, primary_insured_in, count(1) as row_count,
        max(case when email is not null then 'Y' else 'N' end) has_email_in,
        max(case when email is not null then null else quote_insured_sk end)  as quote_insured_sk,
        max(quote_insured_sk)  quote_insured_sk_without_null
        from edw_core.tquote_insured
        where primary_insured_in = 'Yes'
        group by quote_no, effective_dt, transaction_seq_no, primary_insured_in
        having count(1) > 1
        ) as temp

        update tqi set primary_insured_in = 'No'
        from
        edw_core.tquote_insured tqi
        where
        quote_insured_sk in (select quote_insured_sk_final from edw_temp.tquote_insured_update_temp1) 
      
		SET @rows_affected=@@ROWCOUNT; 
	
		SET @new_last_source_extract_ts = '2017-01-01'
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;	

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_insured_update_temp1
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
