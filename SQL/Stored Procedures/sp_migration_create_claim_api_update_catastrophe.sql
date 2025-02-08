/****** Object:  StoredProcedure [edw_core].[sp_migration_create_claim_api_update_catastrophe]    Script Date: 7/02/2025 10:55:29 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Description: This procedures load data in table to update cat code for claim
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	12-02-2024				Yunus Mohammed				1. Created procedure
--	02-07-2025				Hernando Gonzalez			2. Included new logic for PROD
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

		-- ************Start************
        DROP TABLE IF EXISTS [edw_temp].[migration_create_claim_api_update_catastrophe_temp1];

		SELECT DISTINCT
			mclm.claimNumber,
			mclm.claimReferenceNumber,
			mclm.accidentCode,
			(
				'{ "data": { ' +
				'"id": "' + ISNULL(JSON_VALUE(api_response, '$.claimReferenceNumber'), '') + '", ' +
				'"type": "claim", ' +
				'"attributes": { ' +
				'"cf_cat_code_' + ISNULL(cfdef.generated_code, 'unknown') + '": "' + ISNULL(cfclm.prefixed_code, 'unknown') + '"' +
				' } } }' 
			) AS [data],
			update_ts,
			GETDATE() AS create_ts
		INTO [edw_temp].[migration_create_claim_api_update_catastrophe_temp1]
		FROM edw_stage.migration_create_claim_api mclm
		CROSS APPLY OPENJSON(api_response)
		WITH (
			claimNumber NVARCHAR(100) '$.claimNumber',
			claimReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
		) AS clm
		INNER JOIN edw_stage_snapsheet.custom_field_enumeration_options cfclm 
			ON cfclm.name LIKE mclm.accidentCode + '%'
		LEFT JOIN edw_stage_snapsheet.custom_field_definitions cfdef 
			ON TRY_CAST(LEFT(cfclm.[name], 2) AS INT) = TRY_CAST(SUBSTRING(cfdef.[name], 3, 2) AS INT)
			AND cfdef.[name] LIKE (
				CASE 
					-- 2025
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) < 61 AND LEFT(cfclm.[name], 2) = '25'
						THEN '%Pt. 1%'
					/*WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) >= 61 AND LEFT(cfclm.[name], 2) = '25'
						THEN '%Pt. 2%'*/
					-- 2024
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) < 72 AND LEFT(cfclm.[name], 2) = '24'
						THEN '%Pt. 1%'
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) >= 72 AND LEFT(cfclm.[name], 2) = '24'
						THEN '%Pt. 2%'
					-- 2023
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) >= 24 AND LEFT(cfclm.[name], 2) = '23'
						THEN '%Pt. 1%'
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) < 24 AND LEFT(cfclm.[name], 2) = '23'
						THEN '%Pt. 2%'
					-- 2022
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) >= 14 AND LEFT(cfclm.[name], 2) = '22'
						THEN '%Pt.1%'
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) < 14 AND LEFT(cfclm.[name], 2) = '22'
						THEN '%Pt. 2%'
					-- 2021
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) >= 25 AND LEFT(cfclm.[name], 2) = '21'
						THEN '%Pt. 1%'
					WHEN TRY_CAST(SUBSTRING(cfclm.[name], 3, 2) AS INT) < 25 AND LEFT(cfclm.[name], 2) = '21'
						THEN '%Pt. 2%'
					-- 2020
					ELSE '%2020 CAT Codes%'
				END
			)
		WHERE 
			api_status = 'Success'
			AND api_response IS NOT NULL
			AND mclm.claimNumber = clm.claimNumber
			AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
			-- case when [status] = 'OPEN' THEN 'DRAFT' ELSE [status] END AS [status]

        -- Start Insert process
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
GO