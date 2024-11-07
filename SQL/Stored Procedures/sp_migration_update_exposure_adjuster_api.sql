SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Description: This procedures load table migration_update_exposure_adjuster_api
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	11-07-2024				Alberto Almario				1. Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_update_exposure_adjuster_api]
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
        
        DROP TABLE IF EXISTS [edw_temp].[migration_update_exposure_adjuster_api_temp1];

        -- * Create temp table using CROSS APPLY to extract data from JSON column.
        SELECT
            JSON_VALUE(api_response, '$.claimNumber') AS claimNumber,
            JSON_VALUE(api_response, '$.claimReferenceNumber') AS claimReferenceNumber,
            exposure.exposureReferenceNumber,
            exposure.externalReferenceNumber,
            substring(exposure.externalReferenceNumber,1,charindex('-',exposure.externalReferenceNumber)-1) as exposure_id,
            update_ts
        INTO [edw_temp].[migration_update_exposure_adjuster_api_temp1]
        FROM edw_stage.migration_create_claim_api
        CROSS APPLY
            OPENJSON(api_response, '$.exposures')
            WITH (
                exposureReferenceNumber NVARCHAR(100) '$.exposureReferenceNumber',
                externalReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
            ) AS exposure
        WHERE 1=1
        AND api_status = 'Success'
        AND api_response is not null
        AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
        -- AND claimNumber = 'C24HOA00064'
        ;


        -- * Start Insert process
        insert into edw_stage.migration_update_exposure_adjuster_api
        (
            claim_no, 
            exposure_id, 
            adjuster_nm, 
            exposureReferenceNumber, 
            externalReferenceNumber,
            snapsheet_adjuster_id,
            create_ts,
            api_status,
            [data]
        )
        SELECT 
            tmp1.claimNumber, 
            tmp1.exposure_id,
            su.[name] as adjuster_nm,
            tmp1.exposureReferenceNumber,
            tmp1.externalReferenceNumber,
            su.unique_identifier as snapsheet_adjuster_id,
            getdate() as create_ts, 
            'pending' as api_status,
            (
                select
                    tmp1.exposureReferenceNumber as [data.id],
                    'exposure' as [data.type],
                    su.unique_identifier as [data.relationships.claim_handler.data.id],
                    'user' as  [data.relationships.claim_handler.data.type]
                for json path, include_null_values, without_array_wrapper
            ) as [data]
        FROM [edw_temp].[migration_update_exposure_adjuster_api_temp1] as tmp1
        INNER JOIN edw_stage.t_clm_item as i 
            ON i.item_id = tmp1.exposure_id
        INNER JOIN edw_stage.t_clm_object as o 
            ON o.[object_id] = i.[object_id]
        INNER JOIN edw_stage.t_pub_user as u 
            ON u.[USER_ID] = o.owner_id
        INNER JOIN edw_stage_snapsheet.[users] as su 
            ON su.[name] = u.REAL_NAME
        ;
        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_ts) FROM [edw_temp].[migration_update_exposure_adjuster_api_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[migration_update_exposure_adjuster_api_temp1];

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


