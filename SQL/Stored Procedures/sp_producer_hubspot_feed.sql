-- =============================================
-- Author:		Hernando Gonzalez
-- Create Date: 2024-07-17
-- Description: This stored procedure insert info related to Hubspot - Contact
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[producer_hubspot_feed]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT = NULL
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

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[producer_hubspot_feed_temp1];

		-- Start Insert process
        TRUNCATE TABLE [edw_integration].[producer_hubspot_feed]
        ;

		SELECT
			p.broker_id,
			p.producer_id,
			p.email,
			p.first_nm,
			p.last_nm,
			p.phone_no,
			br.broker_status,
			p.title,
			'' as [producer_role],
			p.producer_status,
			getdate() as create_ts,
			getdate() as update_ts,
			@etl_audit_sk AS etl_audit_sk
		INTO [edw_temp].[producer_hubspot_feed_temp1]
		FROM edw_core.tproducer p	
		INNER JOIN edw_core.tbroker br
			ON p.broker_sk = br.broker_sk
		WHERE p.broker_id IN ('56796','56555')
		ORDER BY 6,3,2

        -- Start Insert process
        INSERT INTO [edw_integration].[producer_hubspot_feed](
            [broker_id]
    		,[producer_id]
    		,[email]
    		,[first_nm]
    		,[last_nm]
    		,[phone_no]
    		,[broker_status]
    		,[title]
    		,[producer_role]
    		,[producer_status]
            ,[create_ts]
            ,[update_ts]
            ,[etl_audit_sk]
        )
        SELECT 
            [broker_id],
			[producer_id],
			[email],
			[first_nm],
			[last_nm],
			[phone_no],
			[broker_status],
			[title],
			[producer_role],
			[producer_status],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        FROM [edw_temp].[producer_hubspot_feed_temp1];
        --************End************

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(create_ts) FROM edw_temp.[producer_hubspot_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[producer_hubspot_feed_temp1];

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