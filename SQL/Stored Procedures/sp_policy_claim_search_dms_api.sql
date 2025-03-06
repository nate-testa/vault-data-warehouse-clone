-- ================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 01/16/2025
-- Description: This procedures inserts data for policy claim search dms api
---------------------------------------------------------------------------------------------------
-- Change date		           |Author						                |	Change Description
---------------------------------------------------------------------------------------------------
-- 01/16/2025		        Yunus Mohammed				1. Created this procedure 
-- 03/06/2025		        Hernando Gonzalez			2. AD8779 | Switch to merge to prevent duplicated key
-- ================================================================================================ 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_claim_search_dms_api]
AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

        -- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.policy_claim_search_dms_api_temp1

		SELECT
            policy_no, claim_no, create_ts, update_ts
		INTO edw_temp.policy_claim_search_dms_api_temp1
		FROM
		edw_core.tclaim cl
        WHERE
			--create_ts > @last_source_extract_ts
			GREATEST(update_ts,create_ts) > @last_source_extract_ts;

		MERGE edw_integration.policy_claim_search_dms_api AS Target
	    USING edw_temp.policy_claim_search_dms_api_temp1 AS Source
	    ON Source.claim_no=Target.claim_no
		-- For Inserts
        WHEN NOT MATCHED BY Target THEN
        INSERT (policy_no, claim_no, create_ts, update_ts, etl_audit_sk)
        VALUES (Source.policy_no, Source.claim_no, getdate(), getdate(), @etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			Target.update_ts=Source.update_ts;

		SET @rows_affected=@@ROWCOUNT;

        SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(update_ts,create_ts) FROM edw_temp.policy_claim_search_dms_api_temp1 t1),@last_source_extract_ts);

		-- Update Control
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.policy_claim_search_dms_api_temp1;;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
GO