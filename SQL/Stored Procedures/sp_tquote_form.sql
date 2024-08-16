SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2024-08-14
-- Description: This stored procedure insert and update info related to tquote_form.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_form]
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

        -- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_form_temp1];

        SELECT  
            acct.PolicyNumber as quote_no,
            acct.EffectiveDate as effective_dt,
            acct.ExpirationDate as expiration_dt,
            CASE 
                WHEN acct.TransactionEffectiveDate IS NULL THEN acct.EffectiveDate
                ELSE acct.TransactionEffectiveDate 
            END as transaction_effective_dt,
            acct.CreatedDate as transaction_dt,        
            acct.PolicyChangeNumber as transaction_seq_no,
            qh.quote_history_sk,
            acctvf.Number as form_cd,
            acctvf.edition as form_edition,
            acctvf.Description as form_description,
            acctvf.FormType as form_type,
            acctvf.DocumentType as document_type, 
            CASE 
                WHEN acct.ExternalSourceId IS NOT NULL THEN 2 
                ELSE 4 
            END as source_system_sk
        INTO [edw_temp].[tquote_form_temp1]
        FROM [edw_stage].[AccountTransaction] AS acct
        INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
        INNER JOIN [edw_stage].[AccountTransactionVersionForm] AS acctvf ON acctvf.AccountTransactionVersionId = acctv.Id 
        INNER JOIN [edw_core].[tquote_history] AS qh
            ON acct.PolicyNumber = qh.quote_no 
            AND acct.EffectiveDate = qh.effective_dt
            AND acct.PolicyChangeNumber = qh.transaction_seq_no
        WHERE acct.Stage in ('QUOTE','POLICY')
        AND acct.CreatedDate > @last_source_extract_ts
        

		-- Start Insert process
		INSERT INTO [edw_core].[tquote_form]
        (
            [quote_no],
            [effective_dt],
            [expiration_dt],
            [transaction_effective_dt],
            [transaction_dt],
            [transaction_seq_no],
            [quote_history_sk],
            [form_cd],
            [form_edition],
            [form_desc],
            [form_type],
            [document_type],
            [source_system_sk],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
		)
        SELECT 
            t1.quote_no,
            t1.effective_dt,
            t1.expiration_dt,
            t1.transaction_effective_dt,
            t1.transaction_dt,
            t1.transaction_seq_no,
            t1.quote_history_sk,
            t1.form_cd,
            t1.form_edition,
            t1.form_description,
            t1.form_type,
            t1.document_type,
            t1.source_system_sk,            
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        FROM 
            [edw_temp].[tquote_form_temp1] AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_dt) FROM edw_temp.[tquote_form_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_form_temp1];

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
