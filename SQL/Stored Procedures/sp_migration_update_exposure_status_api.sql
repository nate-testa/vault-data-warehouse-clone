 -- =================================================================================================
 -- Description: This procedures load table migration_update_exposure_status_api
 ---------------------------------------------------------------------------------------------------
 -- Change date 				|Author						                |	Change Description
 ---------------------------------------------------------------------------------------------------
 --	11-14-2024					Alberto Almario				       1. Created procedure
 -- 02-05-2025				    Yunus Mohammed				2. Put check for "All financial transaction must be completed"
 -- ================================================================================================= 
 CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_update_exposure_status_api]
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
        
        DROP TABLE IF EXISTS [edw_temp].[migration_update_exposure_status_api_temp1];

        -- * Create temp table using CROSS APPLY to extract data from JSON column.
        SELECT
            JSON_VALUE(api_response, '$.claimNumber') AS claim_no,
            JSON_VALUE(api_response, '$.claimReferenceNumber') AS claimReferenceNumber,
            exposure.exposureReferenceNumber,
            exposure.externalReferenceNumber,
            substring(exposure.externalReferenceNumber,1,charindex('-',exposure.externalReferenceNumber)-1) as exposure_id,
			i.STATUS_CODE as [status],
            update_ts,
            getdate() as create_ts, 
            'pending' as api_status,
            (
                select
                    exposure.exposureReferenceNumber as [data.id],
                    'exposure' as [data.type],
                    i.STATUS_CODE as [data.attributes.status]
                for json path, include_null_values, without_array_wrapper
            ) as [data]
        INTO [edw_temp].[migration_update_exposure_status_api_temp1]
        FROM
			edw_stage.migration_create_claim_api mclm
			CROSS APPLY
            OPENJSON(api_response, '$.exposures')
            WITH (
                exposureReferenceNumber NVARCHAR(100) '$.exposureReferenceNumber',
                externalReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
            ) AS exposure
			INNER JOIN edw_stage.t_clm_case clm ON mclm.claimNumber = clm.CLAIM_NO
			INNER JOIN edw_stage.t_clm_object obj ON clm.CASE_ID = obj.CASE_ID
			INNER JOIN edw_stage.t_clm_item i ON i.[OBJECT_ID] = obj.[OBJECT_ID] AND
				i.ITEM_ID = substring(exposure.externalReferenceNumber,1,charindex('-',exposure.externalReferenceNumber)-1)
        WHERE
			mclm.api_status = 'Success'
			and i.STATUS_CODE not in ('OPEN','REOPEN')
			AND api_response is not null
			AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
            AND NOT EXISTS
			(
				SELECT 1 FROM edw_stage.migration_create_financial_transaction_api cft
				where cft.claim_no = clm.CLAIM_NO
				and cft.api_status != 'Success'
			)

        -- * Start Insert process
         insert into edw_stage.migration_update_exposure_status_api
         (
             claim_no,
             claimReferenceNumber, 
             exposureReferenceNumber, 
             externalReferenceNumber,
             exposure_id, 
             [status], 
             create_ts,
             api_status,
             [data]
         )
        SELECT
            claim_no,
            claimReferenceNumber,
            exposureReferenceNumber,
            externalReferenceNumber,
            exposure_id,
			[status],
            create_ts, 
            api_status,
            [data]
        FROM [edw_temp].[migration_update_exposure_status_api_temp1]
        ;
        --************End************

 		SET @ROWS_AFFECTED=@@ROWCOUNT;

		
 		-- UPDATE CONTROL TABLE
 		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_ts) FROM [edw_temp].[migration_update_exposure_status_api_temp1]),@last_source_extract_ts);
         EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
 		-- UPDATE AUDIT TABLE
 		SET @parameter_desc= @parameter_desc + ' and last_source_extract_ts <=' + cast(@new_last_source_extract_ts as varchar(200))
 		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

         -- DROP TEMP TABLE
         DROP TABLE IF EXISTS [edw_temp].[migration_update_exposure_status_api_temp1];

 	END TRY
 	BEGIN CATCH
 		DECLARE @ERROR_MESSAGE NVARCHAR(4000)
 		SET @ERROR_MESSAGE = 'ERROR NUMBER:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
 						    ' ERROR STATE:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
 							+ ' ERROR SEVERITY:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
 							CHAR(13) + 'ERROR PROCEDURE:' + ISNULL(ERROR_PROCEDURE(),'') + ' ERROR LINE:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
 							CHAR(13) + 'ERROR MESSAGE:' + ISNULL(ERROR_MESSAGE(),'')
	
 		EXEC [EDW_CORE].[SP_UPD_ERROR_TETL_AUDIT] @ETL_AUDIT_SK,@ERROR_MESSAGE;

 		THROW 99001,'ERROR OCCURED: SEE TETL_AUDIT TABLE FOR MORE INFO', 1;
	
     END CATCH
 END