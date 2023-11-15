

-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Coverage
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 23/10/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 11/13/23		Architha Gudimalla				2. added tran seq no in the joins
-- 11/14/23		Sandeep Gundreddy				3. modified quote_collection_location_sk join
-- ======================================================================================================== 

CREATE or ALTER PROCEDURE [edw_core].[sp_tquote_collection_class_type]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_class_type_temp1];
		SELECT 
			Id, PolicyNumber as quote_no, EffectiveDate, ExpirationDate, [Number]
			,quote_collection_location_sk, quote_history_sk, quote_collection_coverage_sk, quote_home_coverage_sk
			,[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
		INTO [edw_temp].[tquote_collection_class_type_temp1]
		FROM
			(
			SELECT
				acct.Id, acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.[Number]
				,tqcl.quote_collection_location_sk
				,tqh.quote_history_sk
				,tqcc.quote_collection_coverage_sk
				,tqhc.quote_home_coverage_sk
				,accto.[Field], accto.[Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(SELECT
					acct.*
				FROM [edw_stage].[AccountTransaction] acct
				WHERE
					acct.[Stage] IN ('QUOTE','POLICY')
					--AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 removed
					AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = acc.number
				LEFT JOIN edw_core.tquote_collection_location tqcl on tqcl.quote_no=acc.PolicyNumber			
				LEFT JOIN edw_core.tquote_collection_coverage tqcc on tqcc.quote_no=acc.PolicyNumber
						and tqcc.effective_dt=acc.EffectiveDate and tqcc.transaction_seq_no = acc.number
				LEFT JOIN edw_core.tquote_home_coverage tqhc on tqhc.quote_no=acc.PolicyNumber
						and tqhc.effective_dt=acc.EffectiveDate and tqhc.transaction_seq_no = acc.number
				
				
			WHERE
				p.[Name] in ('Collections','Homeowners')
				AND acct.ObjectType = 'CollectionClass'
				AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (
					[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
					)
			) pivottable
			
		-- Start Insert process
		INSERT INTO [edw_core].[tquote_collection_class_type] (
			[quote_no]
           ,[effective_dt]
           ,[expiration_dt]
           ,[transaction_seq_no]
           ,[quote_collection_location_sk]
		   ,[quote_history_sk]
		   ,[quote_home_coverage_sk]
		   ,[quote_collection_coverage_sk]
           ,[class_type]
           ,[scheduled_limit_amt]
           ,[scheduled_highest_value_limit_amt] --
           ,[blanket_limit_amt]
           ,[blanket_highest_value_limit_amt]
           ,[blanket_single_article_limit_amt]
           ,[highest_value_scheduled_item_appraisal_dt]
           ,[source_system_sk]
           ,[create_ts]
           ,[update_ts]
           ,[etl_audit_sk]
		)
		SELECT [quote_no]
           ,[EffectiveDate]
           ,[ExpirationDate]
           ,[Number]
           ,[quote_collection_location_sk]
           ,[quote_history_sk]
		   ,[quote_home_coverage_sk]
		   ,[quote_collection_coverage_sk]
           ,[ClassType]
           ,[ScheduledCoverage]
           ,[ScheduledHighestValueLimit]
           ,[BlanketCoverage]
           ,[BlanketHighestValue]
           ,[BlanketSingleArticleLimit]
           ,[ScheduledItemAppraisalDate]
           ,[source_system_sk]
           ,getdate()
           ,getdate()
		   ,@etl_audit_sk
		FROM 
			[edw_temp].[tquote_collection_class_type_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM edw_temp.[tquote_collection_class_type_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_collection_class_type_temp1];
		
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

