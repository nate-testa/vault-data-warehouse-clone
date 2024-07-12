-- =================================================================================================
-- Description: This procedures updates ebao stage data
---------------------------------------------------------------------------------------------------
-- Change date		    |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/09/24			    Yunus Mohammed				1. Created this procedure
-- 07/12/24			    Architha Gudimalla			2. Updated to edw_core instead of temp
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_update_ebao_stage]

AS
BEGIN
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()

		-- Set last source extract date
		SET @last_source_extract_ts = '20170101'
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

        update edw_stage.t_clm_pol_insured set INSURED_NAME = '4JGDA5JB5JB070266' where INSURED_ID = 18635017  
        update edw_stage.t_clm_pol_insured set INSURED_NAME = '1F66FSDN1M0A01047' where INSURED_ID = 17885597

		SET @rows_affected=@@ROWCOUNT
        
		-- Update audit table
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






