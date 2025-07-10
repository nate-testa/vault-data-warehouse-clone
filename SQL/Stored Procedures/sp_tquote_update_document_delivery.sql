-- ===========================================================================================================================
-- Description: This procedures update document delivery for quote
-----------------------------------------------------------------------------------------------------------------------------
-- Change date              |Author						               |	Change Description
-----------------------------------------------------------------------------------------------------------------------------
-- 06/05/25                 Dinesh Bobbili			              		1. Created this procedure
-- 06/06/25					Dinesh Bobbili								2. Updated document_delivery_to logic
-- =========================================================================================================================== 

CREATE or ALTER  PROCEDURE [edw_core].[sp_tquote_update_document_delivery]
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
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tquote_update_document_delivery_temp1;
	
		SELECT q.quote_sk,
			acc.PolicyNumber,
			acc.EffectiveDate,accdd.*
		into edw_temp.tquote_update_document_delivery_temp1
		FROM edw_stage.Account acc 
        inner join edw_stage.AccountDocumentDelivery accdd on acc.Id = accdd.AccountId
        inner join edw_core.tquote q on q.quote_no = acc.PolicyNumber and q.effective_dt = acc.EffectiveDate
		left join edw_stage.Product pr on acc.ProductId = pr.id
		WHERE
         acc.PolicyNumber is not null 
		and  pr.ProductLine = 'PersonalLines' 
		AND greatest(accdd.CreatedDate,accdd.UpdatedDate)>@last_source_extract_ts;
		
        UPDATE q
		SET 
		    q.document_delivery_to = CASE 
		        WHEN t.SendOnlyToBroker = 1 THEN 'Broker'
		        WHEN t.SendOnlyToBroker = 0 
		             AND t.EmailPrimaryInsured = 0 
		             AND t.MailPrimaryInsured = 0 THEN NULL
		        ELSE 'Customer' 
		    END,
		    q.document_delivery_method = CASE
		        WHEN t.SendOnlyToBroker = 0 
		             AND t.EmailPrimaryInsured = 1 
		             AND t.MailPrimaryInsured = 1 THEN 'Email & Mail'
		        WHEN t.SendOnlyToBroker = 0 
		             AND t.EmailPrimaryInsured = 1 THEN 'Email'
		        WHEN t.SendOnlyToBroker = 0 
		             AND t.MailPrimaryInsured = 1 THEN 'Mail'
		    END
		FROM edw_core.tquote q
		INNER JOIN edw_temp.tquote_update_document_delivery_temp1 t  
		ON q.quote_sk = t.quote_sk;


		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(CreatedDate,UpdatedDate)) FROM edw_temp.tquote_update_document_delivery_temp1 t1),@last_source_extract_ts);

		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;	

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

		DROP TABLE IF EXISTS edw_temp.tquote_update_document_delivery_temp1

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
