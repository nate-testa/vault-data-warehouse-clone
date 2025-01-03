-- =================================================================================================
-- Description: This procedures load data in table to update cat code for claim
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	12-02-2024				Yunus Mohammed				1. Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_create_claim_api_update_catastrophe]
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
        
        DROP TABLE IF EXISTS [edw_temp].[migration_create_claim_api_update_catastrophe_temp1];

		SELECT
			distinct mclm.claimNumber,mclm.claimReferenceNumber,mclm.accidentCode,
			(
			SELECT
				JSON_VALUE(api_response, '$.claimReferenceNumber') as [data.id],
				'claim' as [data.type],				
				cfclm.option_prefixed_code as [data.attributes.cf_cat_code_292e]
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			) AS [data],
			update_ts,
			getdate() as create_ts
		INTO [edw_temp].[migration_create_claim_api_update_catastrophe_temp1]
		from
			edw_stage.migration_create_claim_api mclm
			CROSS APPLY
			OPENJSON(api_response)
			WITH (
			claimNumber NVARCHAR(100) '$.claimNumber',
			claimReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
			) AS clm
			inner join edw_stage_snapsheet.custom_field_claims_enumeration_values cfclm on
			cfclm.option_name like mclm.accidentCode + '%'
		where
			api_status = 'Success'
			and api_response is not null
			and mclm.claimNumber = clm.claimNumber
			AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
			-- case when [status] = 'OPEN' THEN 'DRAFT' ELSE [status] END AS [status],		
			

        -- * Start Insert process
        insert into edw_stage.migration_create_claim_api_update_catastrophe
        (
            claimNumber,claimRerenceNumber,accidentCode, [data] ,create_ts,api_status
        )
        SELECT 
            claimNumber,claimReferenceNumber, accidentCode,[data],
            create_ts, 
            'pending' as api_status
        FROM [edw_temp].[migration_create_claim_api_update_catastrophe_temp1]
        ;
        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_ts) FROM [edw_temp].[migration_create_claim_api_update_catastrophe_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[migration_create_claim_api_update_catastrophe_temp1];

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