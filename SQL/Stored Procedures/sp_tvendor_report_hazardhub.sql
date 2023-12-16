SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Author:	Alberto Almario
-- Description: This procedures loads vendor reports hazardhub data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 12/11/23		Alberto Almario				1. Created this procedure  
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tvendor_report_hazardhub]
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

        DROP TABLE IF EXISTS [edw_temp].[tvendor_report_hazardhub_temp1];
        SELECT 
            acc.policynumber, 
            acc.effectivedate, 
            accr.dateordered, 
            accr.dateTimeRecieved, 
            accr.dateTimeCompleted, 
            accr.TransactionStatus, 
            accr.[source], 
            accr.[reporttype], 
            accri.[Category],
            accri.[Group], 
            accri.[Label],
            accri.[Value],
            GREATEST(accri.UpdatedDate,accri.CreatedDate) as UpdatedDate
        INTO [edw_temp].[tvendor_report_hazardhub_temp1]
        FROM edw_stage.Account AS acc 
        INNER JOIN edw_stage.AccountReport AS accr ON accr.AccountId = acc.Id
        INNER JOIN edw_stage.AccountReportItem AS accri ON accr.Id = accri.ReportId 
        WHERE acc.PolicyNumber IS NOT NULL
        AND acc.effectivedate IS NOT NULL
        AND accr.source = 'HazardHub'
        AND GREATEST(accri.UpdatedDate,accri.CreatedDate) > @last_source_extract_ts
        ;


        INSERT INTO [edw_stage].[tvendor_report_HazardHub]
        SELECT 
            vrh.policynumber, 
            vrh.effectivedate, 
            vrh.dateordered, 
            vrh.dateTimeRecieved, 
            vrh.dateTimeCompleted, 
            vrh.TransactionStatus,
            (
                SELECT 
                    vrhj.[source], 
                    vrhj.[reporttype], 
                    vrhj.[Category],
                    vrhj.[Group], 
                    vrhj.[Label],
                    vrhj.[Value] 
                FROM [edw_temp].[tvendor_report_hazardhub_temp1] AS vrhj
                WHERE 1=1
                    AND vrhj.policynumber = vrh.policynumber
                    AND vrhj.effectivedate = vrh.effectivedate
                    AND COALESCE(vrhj.dateordered,'') = COALESCE(vrh.dateordered,'')
                    AND COALESCE(vrhj.dateTimeRecieved,'') = COALESCE(vrh.dateTimeRecieved,'')
                    AND COALESCE(vrhj.dateTimeCompleted,'') = COALESCE(vrh.dateTimeCompleted,'')
                    AND COALESCE(vrhj.TransactionStatus,'') = COALESCE(vrh.TransactionStatus,'')
                FOR JSON PATH
            ) as JSON_Columns,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk 
        FROM [edw_temp].[tvendor_report_hazardhub_temp1] AS vrh
        GROUP BY 
            vrh.policynumber, 
            vrh.effectivedate, 
            vrh.dateordered, 
            vrh.dateTimeRecieved, 
            vrh.dateTimeCompleted, 
            vrh.TransactionStatus

        SET @rows_affected=@@ROWCOUNT
        ;

        --************End************


		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UpdatedDate) FROM edw_temp.[tvendor_report_hazardhub_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[tvendor_report_hazardhub_temp1];

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
