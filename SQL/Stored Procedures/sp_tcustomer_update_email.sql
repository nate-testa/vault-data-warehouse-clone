-- =============================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures updates email for customers
------------------------------------------------------------------------------------------------------------
-- Change date |Author					                            |	Change Description
------------------------------------------------------------------------------------------------------------
-- 09/17/25		Yunus Mohammed                          1. Created this procedure
-- ============================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcustomer_update_email]

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

        SELECT  CAST(i.ReferenceCode AS VARCHAR(255)) AS ReferenceCode,i.email
        INTO edw_temp.[tcustomer_update_email_temp1] 
        FROM edw_stage.Insured i
        INNER JOIN edw_core.tcustomer c ON	CAST(i.referencecode AS VARCHAR(255)) = c.customer_id
        WHERE
            c.customer_id != 'LIT9999'
            AND trim (isnull (i.Email,'')) != trim (isnull (c.email,'')) ;
    
        UPDATE c
        SET
            c.email = t.email,
            update_ts = GETDATE()
        FROM
            edw_core.tcustomer c
            INNER JOIN edw_temp.[tcustomer_update_email_temp1]  t on c.customer_id = t.ReferenceCode

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01' 

        DROP TABLE IF EXISTS edw_temp.[tcustomer_update_email_temp1]
		
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