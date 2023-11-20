 -- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates claim catastrophe code
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/07/23			Yunus Mohammed				1. Made changes to fix the errors on first run 
-- 11/20/23			Yunus Mohammed				2. Added Throw statement 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcatastrophe]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		-- Get last source extract date
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		-- Create temp table with name as tcatastrophe_temp1
		DROP TABLE IF EXISTS edw_temp.tcatastrophe_temp1 
		SELECT
		DISTINCT
		ACCIDENT_CODE AS accident_code,
		ACCIDENT_NAME as accident_name,
		CAST(ACCIDENT_DESC AS VARCHAR(MAX)) AS accident_desc
		INTO edw_temp.tcatastrophe_temp1
		FROM 
		edw_stage.t_clm_accident pc
					
		-- Insert and Update [tinternal_coverage] table
		MERGE [edw_core].[tcatastrophe]  AS Target
		USING edw_temp.tcatastrophe_temp1 AS Source
		ON TRIM(Source.accident_code)=TRIM(Target.catastrophe_cd)
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				catastrophe_cd,catastrophe_nm,catastrophe_desc,source_system_sk,
				create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
			Source.accident_code,Source.accident_name,Source.accident_desc,3,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.catastrophe_nm=Source.accident_name,
		Target.catastrophe_desc	= Source.accident_desc,
		Target.[update_ts]=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcatastrophe_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

