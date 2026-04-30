SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ========================================================================================================================================
-- Description: This procedures insert and update info related to Quote Manuscript
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date 			|Author							|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 06/20/23				Hernando Gonzalez Garcia		1. Created this procedure 
-- 01/17/24				Architha Gudimalla				2. Modified for errors after first run  
-- 09/07/24				Yunus Mohammed					3. Use ValueBlob if Value field is null for manuscript_title an desc
-- 08/20/24				Yunus Mohammed					4. Used IncludeManuscript indicator
-- 04/30/26				Yunus Mohammed					5. AD-12470 - Modified code for performance issues
-- ======================================================================================================================================== 
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_manuscript_temp2];

		SELECT
			acct.Id,acct.PolicyNumber,acct.EffectiveDate,acct.ExpirationDate,acct.[Number], acct.CreatedDate,acctvo.[Index],
			case when acct.ExternalSourceId is not NULL then 2--(AV2) 
				Else 4 --(Metal)
			end as [source_system_sk]
		INTO edw_temp.tquote_manuscript_temp1
		FROM
			[edw_stage].[AccountTransaction] acct
			INNER JOIN [edw_stage].[Product] p on p.Id = acct.ProductId
			INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
			INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
			AND acctvo.ObjectType in ('Homeowner','Condo','Collection','PersonalExcessLiability')
			INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.Id 
				AND acctvof.Field = 'IncludeManuscript' AND acctvof.[Value] = 'Yes'
		WHERE
		acct.[Stage] IN ('QUOTE','POLICY')
		AND acct.CreatedDate > @last_source_extract_ts

		SELECT 
			PolicyNumber as quote_no, EffectiveDate, ExpirationDate, [Number] as transaction_seq_no
			,quote_history_sk
			,ManuscriptTitle, ManuscriptNumber, ManuscriptDescription
			,source_system_sk
			,CreatedDate
			,[Index] as manuscript_seq_no
		INTO [edw_temp].[tquote_manuscript_temp2]
		FROM
			(
			SELECT
				acct.PolicyNumber, acct.EffectiveDate, acct.ExpirationDate, acct.[Number], acct.CreatedDate, acct.[Index],acct.[source_system_sk]
				,tqh.[quote_history_sk]
				,acctvof.[Field] 
				,case
					when acctvof.Field in ('ManuscriptDescription','ManuscriptTitle') and len(acctvof.[Value])= 0 then NULLIF(acctvof.[ValueBlob],'')
				else NULLIF(acctvof.[Value], '') end as [Value]	
			FROM
				edw_temp.[tquote_manuscript_temp1] acct
				INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
				INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				--AND acctvo.ObjectType in ('Homeowner','Condo','Collection','PersonalExcessLiability')
				INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
				LEFT JOIN [edw_core].[tquote_history] tqh on tqh.quote_no=acct.PolicyNumber 
					AND tqh.effective_dt=acct.EffectiveDate and tqh.transaction_seq_no = acct.[Number]
			WHERE
				acctvof.Field in ('ManuscriptDescription','ManuscriptTitle','ManuscriptNumber') 
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
			,[manuscript_seq_no]
		)
		SELECT
			[quote_no]
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
			,[manuscript_seq_no]
		FROM 
			[edw_temp].[tquote_manuscript_temp2]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM edw_temp.[tquote_manuscript_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_manuscript_temp1];
		DROP TABLE IF EXISTS edw_temp.[tquote_manuscript_temp2];

		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
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