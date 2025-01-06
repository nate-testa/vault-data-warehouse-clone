-- =================================================================================================
-- Description: This procedures update policy webhook phone no and email
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	11-28-2024				Yunus Mohammed				Created procedure
-- ================================================================================================= 
CREATE OR ALTER   PROCEDURE [edw_core].[sp_migration_create_financial_transaction_api_update_contactinfo]
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

		select financial_transaction_id,[data],create_ts
		into edw_temp.sp_migration_create_financial_transaction_api_temp1
		from edw_stage.migration_create_financial_transaction_api
		where create_ts > @last_source_extract_ts
		
		update [target]
		set
			[target].[data] = JSON_MODIFY
			(
				JSON_MODIFY([source].[data] collate SQL_Latin1_General_CP1_CI_AS, '$.data.attributes.payee.[0].value', '7272901574'),
				'$.data.attributes.payee.contact_methods[1].value', 'Farhad.Imam@Vault.Insurance'
			)
		from
			edw_stage.migration_create_financial_transaction_api [target]
			inner join edw_temp.sp_migration_create_financial_transaction_api_temp1 as [source] on
			[target].financial_transaction_id = [source].financial_transaction_id


		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM [edw_temp].sp_migration_create_financial_transaction_api_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS [edw_temp].migration_create_financial_transaction_api_temp1;
	
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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