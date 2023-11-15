-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 15/09/2023
-- Description: This procedures inserts and updates claim sub cause of loss

CREATE OR ALTER PROCEDURE [edw_core].[sp_tsub_cause_of_loss]

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
		DROP TABLE IF EXISTS edw_temp.tsub_cause_of_loss_temp1
		SELECT
			subcl.cause_of_loss_cd,
			cl.cause_of_loss_desc,
			subcl.sub_cause_of_loss_cd,
			subcl.sub_cause_of_loss_desc
		INTO edw_temp.tsub_cause_of_loss_temp1
		FROM
		(
			SELECT
			DISTINCT
			REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.CauseofLossCode'),'"','') AS cause_of_loss_cd,
			REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.DisplayValue'),'"','') AS sub_cause_of_loss_desc,
			REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.DataValue'),'"','') AS sub_cause_of_loss_cd
			FROM
			edw_stage.t_dd_busi_data_table_record 
			WHERE DATA_TABLE_ID=98100257349
		) AS subcl
		LEFT JOIN edw_core.tcause_of_loss cl ON subcl.cause_of_loss_cd=cl.cause_of_loss_cd
		LEFT JOIN edw_core.tsub_cause_of_loss scl ON subcl.sub_cause_of_loss_cd=scl.sub_cause_of_loss_cd

		-- Insert and Update tcause_of_loss table
		MERGE edw_core.tsub_cause_of_loss  AS Target
		USING edw_temp.tsub_cause_of_loss_temp1 AS Source
		ON Source.sub_cause_of_loss_cd=Target.sub_cause_of_loss_cd
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				cause_of_loss_cd,cause_of_loss_desc,sub_cause_of_loss_cd,
				sub_cause_of_loss_desc,source_system_sk,create_ts,
				update_ts,etl_audit_sk
			)
		VALUES
			(
			Source.cause_of_loss_cd,Source.cause_of_loss_desc,Source.sub_cause_of_loss_cd,Source.sub_cause_of_loss_desc,
			3,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.sub_cause_of_loss_desc=Source.sub_cause_of_loss_desc,
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
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
	END CATCH
END

