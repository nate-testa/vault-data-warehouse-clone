-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Coverage
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 08/16/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 10/09/23		Architha Gudimalla				2. Made changes after sandeep renamed the coll tables
-- 10/09/23		Sandeep  Gundreddy				3. Added Homeowners to product filter
-- 10/13/23		Architha Gudimalla				4. Correction the location table join
-- 11/02/23		Architha Gudimalla				5. Updated left joins to inner
-- 03/21/24		Architha Gudimalla				6. Added deleted flag
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcollection_class_type]
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
		DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp1];
		SELECT 
			Id, PolicyNumber, EffectiveDate, IssuedDate, ExpirationDate, transaction_dt, PolicyChangeNumber
			,collection_location_sk, policy_history_sk, collection_coverage_sk, home_coverage_sk
			,[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			,class_deleted_in
		INTO [edw_temp].[tcollection_class_type_temp1]
		FROM
			(
			SELECT
				acct.Id, acc.PolicyNumber, acc.EffectiveDate, acc.IssuedDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, acc.PolicyChangeNumber
				,loc.[collection_location_sk] as [collection_location_sk], his.[policy_history_sk] as [policy_history_sk],
				cov.collection_coverage_sk, hcov.home_coverage_sk
				,accto.[Field], accto.[Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
            	,acct.IsdeletedOnPolicyChange as class_deleted_in
			FROM
				(SELECT
					acct.*
				FROM [edw_stage].[AccountTransaction] acct
				WHERE
					acct.[State] ='ISSUED' --- Review BOUND transactions
					--AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 removed
					AND GREATEST(acct.IssuedDate)>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				INNER JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				LEFT JOIN [edw_core].[tcollection_location] loc ON loc.policy_no = acc.PolicyNumber and loc.effective_dt = acc.EffectiveDate
				LEFT JOIN [edw_core].[tcollection_coverage] cov on cov.policy_no = acc.PolicyNumber and cov.effective_dt = acc.EffectiveDate and cov.transaction_seq_no = acc.policychangenumber
				LEFT JOIN [edw_core].[thome_coverage] hcov on hcov.policy_no = acc.PolicyNumber and hcov.effective_dt = acc.EffectiveDate and hcov.transaction_seq_no = acc.policychangenumber
				LEFT JOIN [edw_core].[tpolicy_history] his ON his.policy_no = acc.PolicyNumber AND his.effective_dt=acc.EffectiveDate AND his.transaction_seq_no = acc.policychangenumber
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
		INSERT INTO [edw_core].[tcollection_class_type] (
			[policy_no]
           ,[effective_dt]
           ,[transaction_effective_dt]
           ,[expiration_dt]
           ,[transaction_dt]
           ,[transaction_seq_no]
           ,[collection_location_sk]
           ,[policy_history_sk]
		   ,[collection_coverage_sk]
		   ,[home_coverage_sk]
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
		   ,class_deleted_in
		)
		SELECT [PolicyNumber]
           ,[EffectiveDate]
           ,[transaction_dt]
           ,[ExpirationDate]
           ,[IssuedDate]
           ,[PolicyChangeNumber]
           ,[collection_location_sk]
           ,[policy_history_sk]
		   ,[collection_coverage_sk]
		   ,[home_coverage_sk]
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
		   ,CASE WHEN class_deleted_in = 1 THEN 'Yes' ELSE 'No' END as class_deleted_in
		FROM 
			[edw_temp].[tcollection_class_type_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.[tcollection_class_type_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tcollection_class_type_temp1];
		
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

