SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/7/2023
-- Description: This procedures inserts and updates claim cause of loss
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/07/23			Yunus Mohammed				1. Created procedure
-- 11/18/23			Sandeep Gundreddy			2. Modified logic to use edw_stage.t_clm_losscause
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcause_of_loss]

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

		-- Create temp table with name as tcause_of_loss_temp1
		DROP TABLE IF EXISTS edw_temp.tcause_of_loss_temp1 
		SELECT
		DISTINCT
            loss_cause_code as cause_of_loss_cd,
			loss_cause_name as cause_of_loss_desc
		INTO edw_temp.tcause_of_loss_temp1
		FROM 
		edw_stage.t_clm_losscause

		-- Insert and Update tcause_of_loss table
		MERGE edw_core.tcause_of_loss  AS Target
		USING edw_temp.tcause_of_loss_temp1 AS Source
		ON Source.cause_of_loss_cd=Target.cause_of_loss_cd
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				cause_of_loss_cd,cause_of_loss_desc,source_system_sk,
				create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
			Source.cause_of_loss_cd,Source.cause_of_loss_desc,3,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.cause_of_loss_desc	= Source.cause_of_loss_desc,
		Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcause_of_loss_temp1
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

GO
