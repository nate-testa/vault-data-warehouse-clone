SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Description: This procedures inserts tcause_of_loss snapsheet data
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/15/2024		Alberto Almario				1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcause_of_loss_snapsheet]
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

		DROP TABLE IF EXISTS edw_temp.tcause_of_loss_snapsheet_temp1;


		WITH claim_data AS (
			SELECT 
				claim_type, 
				loss_type, 
				MAX(updated_at) AS updated_at
			FROM edw_stage_snapsheet.claims
			WHERE loss_type NOT IN (
				SELECT cause_of_loss_desc 
				FROM edw_core.tcause_of_loss 
				WHERE cause_of_loss_cd LIKE 'SS_%'
			)
			AND updated_at > @last_source_extract_ts
			GROUP BY claim_type, loss_type
		),
		last_sequence AS (
			SELECT 
				CASE 
					WHEN cause_of_loss_cd LIKE 'SS_AU_%' THEN 'auto'
					WHEN cause_of_loss_cd LIKE 'SS_PEL_%' THEN 'liability'
					WHEN cause_of_loss_cd LIKE 'SS_HO_%' THEN 'property'
					WHEN cause_of_loss_cd LIKE 'SS_CO_%' THEN 'condo'
					WHEN cause_of_loss_cd LIKE 'SS_LUX_%' THEN 'collections'
					ELSE 'other'
				END AS claim_type,
				MAX(CAST(SUBSTRING(cause_of_loss_cd, CHARINDEX('_', cause_of_loss_cd, CHARINDEX('_', cause_of_loss_cd) + 1) + 1, LEN(cause_of_loss_cd)) AS INT)) AS last_number
			FROM edw_core.tcause_of_loss
			WHERE cause_of_loss_cd LIKE 'SS_%'
			GROUP BY 
				CASE 
					WHEN cause_of_loss_cd LIKE 'SS_AU_%' THEN 'auto'
					WHEN cause_of_loss_cd LIKE 'SS_PEL_%' THEN 'liability'
					WHEN cause_of_loss_cd LIKE 'SS_HO_%' THEN 'property'
					WHEN cause_of_loss_cd LIKE 'SS_CO_%' THEN 'condo'
					WHEN cause_of_loss_cd LIKE 'SS_LUX_%' THEN 'collections'
					ELSE 'other'
				END
		)
		SELECT 
			CONCAT(
				CASE 
					WHEN c.claim_type = 'auto' THEN 'SS_AU_' 
					WHEN c.claim_type = 'liability' THEN 'SS_PEL_' 
					WHEN c.claim_type = 'property' THEN 'SS_HO_'
					WHEN c.claim_type = 'condo' THEN 'SS_CO_'
					WHEN c.claim_type = 'collections' THEN 'SS_LUX_'
					ELSE '_OT_' 
				END,
				ROW_NUMBER() OVER (PARTITION BY c.claim_type ORDER BY c.loss_type ASC) + COALESCE(l.last_number, 0)
			) AS cause_of_loss_cd,
			c.loss_type AS cause_of_loss_desc,
			5 AS source_system_sk,
			c.updated_at
		INTO edw_temp.tcause_of_loss_snapsheet_temp1
		FROM claim_data c
		LEFT JOIN last_sequence l ON c.claim_type = l.claim_type
		;

		-- Start Insert process
		INSERT INTO edw_core.tcause_of_loss
		(
			cause_of_loss_cd,
			cause_of_loss_desc,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT 
			cause_of_loss_cd,
			cause_of_loss_desc,
			source_system_sk,
			GETDATE() AS create_ts,
			GETDATE() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tcause_of_loss_snapsheet_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(updated_at) FROM edw_temp.tcause_of_loss_snapsheet_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcause_of_loss_snapsheet_temp1

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
