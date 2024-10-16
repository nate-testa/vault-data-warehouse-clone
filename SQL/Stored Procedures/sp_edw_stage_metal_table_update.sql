SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================================================
-- Description: This procedures inserts and updates TPolicy 
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 10/15/24		Architha Gudimalla				1. Created this procedure  
-- ======================================================================================================================================== 

CREATE OR ALTER     PROCEDURE [edw_core].[sp_edw_stage_metal_table_update]

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

			DROP TABLE IF EXISTS edw_temp.metal_table_temp1;
			select [id] 
			into edw_temp.metal_table_temp1
			from edw_stage.Account 
			where EffectiveDate is null;

			update a
			set EffectiveDate = cast(createddate as date)
			from edw_stage.Account a
			where exists (select 'x' from edw_temp.metal_table_temp1 b where a.[id] = b.[id]);

			DROP TABLE IF EXISTS edw_temp.metal_table_temp1;
			select [id] 
			into edw_temp.metal_table_temp1
			from edw_stage.Account 
			where ExpirationDate is null;

			update a
			set ExpirationDate = cast(createddate as date)
			from edw_stage.Account a
			where exists (select 'x' from edw_temp.metal_table_temp1 b where a.[id] = b.[id]); 
		
		SET @rows_affected=@@ROWCOUNT;
		SET @new_last_source_extract_ts = '2017-01-01';

        DROP TABLE IF EXISTS edw_temp.metal_table_temp1; 
		
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

