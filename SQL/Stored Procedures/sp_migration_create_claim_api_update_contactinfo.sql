-- =================================================================================================
-- Description: This procedures update claim phone no and email
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						                   |	Change Description
---------------------------------------------------------------------------------------------------
--	11-27-2024				Yunus Mohammed                  Created procedure
-- 01-06-2025               Yunus Mohammed                  Updated record count logic
-- ================================================================================================= 
CREATE OR ALTER   PROCEDURE [edw_core].[sp_migration_create_claim_api_update_contactinfo]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));

		declare @claimParties nvarchar(max),@claimNumber varchar(255)

		drop table if exists edw_temp.migration_create_claim_api_update_contactinfo_temp1
		SELECT
              claimNumber,claimParties,create_ts
		INTO edw_temp.migration_create_claim_api_update_contactinfo_temp1
        FROM edw_stage.migration_create_claim_api
		where
			create_ts > @last_source_extract_ts
		DECLARE cur_main CURSOR FOR
        SELECT
              claimNumber,claimParties
        FROM edw_temp.migration_create_claim_api_update_contactinfo_temp1		

		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @claimNumber, @claimParties
		WHILE @@FETCH_STATUS = 0
		BEGIN

			UPDATE edw_stage.migration_create_claim_api
			SET				
				claimParties = (
				select '[' +
						STRING_AGG(
						   JSON_MODIFY( JSON_MODIFY([value] collate SQL_Latin1_General_CP1_CI_AS, '$.contactMethods[0].value', '7272901574')
						   , '$.contactMethods[1].value', 'Farhad.Imam@Vault.Insurance'
						   )
   
						   ,','
						 ) 
						+ ']'
						 as new_claim_parties
						from
						OPENJSON (@claimParties) claimParties
				)
				
			WHERE
				claimNumber = @claimNumber

			FETCH NEXT FROM cur_main INTO @claimNumber,@claimParties
		END

		CLOSE cur_main;

		DEALLOCATE cur_main;
		
		-- SET @rows_affected=@@ROWCOUNT;
        SELECT @rows_affected  = COUNT(*) FROM edw_temp.migration_create_claim_api_update_contactinfo_temp1

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM edw_temp.migration_create_claim_api_update_contactinfo_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_update_contactinfo_temp1;
	
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		drop table if exists edw_temp.migration_create_claim_api_update_contactinfo_temp1

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