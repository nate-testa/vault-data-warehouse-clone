SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Description: This procedures inserts catastrophe snapsheet data
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/15/2024		Alberto Almario				1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcatastrophe_snapsheet]
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

		--************Start************

		DROP TABLE IF EXISTS edw_temp.tcatastrophe_snapsheet_temp1;


		SELECT 
			option_name,
			LEFT(option_name, CHARINDEX('|', option_name) - 1) AS catastrophe_cd,
			SUBSTRING(
				option_name, 
				CHARINDEX('|', option_name) + 1, 
				CHARINDEX('|', option_name, CHARINDEX('|', option_name) + 1) - CHARINDEX('|', option_name) - 1
			) AS catastrophe_nm,
			RIGHT(option_name, LEN(option_name) - CHARINDEX('|', option_name, CHARINDEX('|', option_name) + 1)) AS catastrophe_desc,
			5 AS source_system_sk,
			MAX(option_definition_updated_at) AS option_definition_updated_at
		INTO edw_temp.tcatastrophe_snapsheet_temp1
		FROM edw_stage_snapsheet.custom_field_claims_enumeration_values
		WHERE option_definition_updated_at > @last_source_extract_ts
		GROUP BY 
			option_name,
			LEFT(option_name, CHARINDEX('|', option_name) - 1),
			SUBSTRING(
				option_name, 
				CHARINDEX('|', option_name) + 1, 
				CHARINDEX('|', option_name, CHARINDEX('|', option_name) + 1) - CHARINDEX('|', option_name) - 1
			),
			RIGHT(option_name, LEN(option_name) - CHARINDEX('|', option_name, CHARINDEX('|', option_name) + 1))
		;

		-- Start Insert process
		INSERT INTO edw_core.tcatastrophe
		(
			catastrophe_cd,
			catastrophe_nm,
			catastrophe_desc,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT 
			catastrophe_cd,
			catastrophe_nm,
			catastrophe_desc,
			source_system_sk,
			GETDATE() AS create_ts,
			GETDATE() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tcatastrophe_snapsheet_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(option_definition_updated_at) FROM edw_temp.tcatastrophe_snapsheet_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcatastrophe_snapsheet_temp1

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')

		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
