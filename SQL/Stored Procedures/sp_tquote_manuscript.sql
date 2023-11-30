-- =============================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: <Create Date, , >
-- Description: This procedures insert and update info related to Loss History
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_manuscript]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_manuscript_temp1];
		SELECT 
			PolicyNumber as quote_no, EffectiveDate, ExpirationDate, PolicyChangeNumber as transaction_seq_no
			,quote_history_sk
			,ManuscriptTitle, ManuscriptNumber, ManuscriptDescription
			,source_system_sk --20230717 added
			,CreatedDate
		INTO [edw_temp].[tquote_manuscript_temp1]
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.PolicyChangeNumber
				,tqh.[quote_history_sk]
				,accto.[Field], NULLIF(accto.[Value], '') as [Value]
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
				,acc.CreatedDate
			FROM
				(SELECT
					*
				FROM [edw_stage].[AccountTransaction]
				WHERE
					[Stage] IN ('QUOTE','POLICY')
					AND CreatedDate > @last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				INNER JOIN [edw_core].[tquote_history] tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = acc.number
			WHERE
				acct.ObjectType = 'Manuscript'
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (ManuscriptTitle, ManuscriptNumber, ManuscriptDescription)
			) pivottable
			
		-- Start Insert process
		INSERT INTO [edw_core].[tquote_manuscript] (
			[quote_no]
			,[effective_dt]
			,[expiration_dt]
			,[transaction_seq_no]
			,[quote_history_sk]
			,[manuscript_no]
			,[manuscript_title]
			,[manuscript_desc]
			,[source_system_sk]
			,[create_ts]
			,[update_ts]
			,[etl_audit_sk]
		)
		SELECT [quote_no]
      		,[EffectiveDate]
      		,[ExpirationDate]
      		,[transaction_seq_no]
      		,[quote_history_sk]
      		,[ManuscriptNumber]
      		,[ManuscriptTitle]
      		,[ManuscriptDescription]
      		,[source_system_sk]
      		,getdate()
      		,getdate()
		   ,@etl_audit_sk
		FROM 
			[edw_temp].[tquote_manuscript_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM edw_temp.[tquote_manuscript_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_manuscript_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END