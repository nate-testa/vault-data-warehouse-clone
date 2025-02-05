-- =================================================================================================
-- Description: This procedures load table migration_update_exposure_adjuster_api
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	12-02-2024				Yunus Mohammed				1. Created procedure
-- 02-05-2025				Yunus Mohammed				2. Put check for "All financial transaction must be completed"
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_create_claim_api_update_status]
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
        
        DROP TABLE IF EXISTS [edw_temp].[migration_create_claim_api_update_status_temp1];

        -- * Create temp table using CROSS APPLY to extract data from JSON column.
	-- id,[type],[data],update 
		SELECT
			mclm.claimNumber as claim_no,
			JSON_VALUE(api_response, '$.claimReferenceNumber') AS [id],
			'claim' as [type],
			(
			SELECT
				JSON_VALUE(api_response, '$.claimReferenceNumber') as [data.id],
				'claim' as [data.type],				
				JSON_VALUE(api_response, '$.claimNumber') AS [data.attributes.claim_number],
				CASE 
				WHEN cstat.status_code IN('1','2','5') THEN 'DRAFT'
				WHEN cstat.status_code IN('3','4','6') THEN 'CLOSED'
				ELSE cstat.status_name
				END as [data.attributes.status]
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			) AS [data],
			update_ts,
			getdate() as create_ts
			
		INTO [edw_temp].[migration_create_claim_api_update_status_temp1]
		FROM
			edw_stage.migration_create_claim_api mclm
			CROSS APPLY
			OPENJSON(api_response)
			WITH (
			claimNumber NVARCHAR(100) '$.claimNumber',
			claimReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
			) AS clm
			INNER JOIN edw_stage.t_clm_case c ON c.CLAIM_NO = mclm.claimNumber
			LEFT JOIN edw_stage.t_clm_case_status cstat ON c.CASE_STATUS = cstat.STATUS_CODE
			WHERE
			api_status = 'Success'
			-- If already open in that case we don't have to update status again
			and cstat.status_code NOT IN ('1', '2', '5')
			AND api_response is not null
			AND NOT EXISTS
			(
				SELECT 1 FROM edw_stage.migration_create_financial_transaction_api cft
				where cft.claim_no = c.CLAIM_NO
				and cft.api_status != 'Success'
			)
			AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
			-- case when [status] = 'OPEN' THEN 'DRAFT' ELSE [status] END AS [status],

        -- * Start Insert process
        insert into edw_stage.migration_create_claim_api_update_status
        (
            claim_no,id,[type],[data],
            create_ts,
            api_status            
        )
        SELECT 
            claim_no,id,[type],[data],
            create_ts, 
            'pending' as api_status            
        FROM [edw_temp].[migration_create_claim_api_update_status_temp1]
        ;
        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_ts) FROM [edw_temp].[migration_create_claim_api_update_status_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[migration_create_claim_api_update_status_api_temp1];

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