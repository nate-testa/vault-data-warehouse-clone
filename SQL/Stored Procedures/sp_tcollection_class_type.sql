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
-- 05/28/24		Alberto Almario					7. Integrate Premium Adjustments data into EDW - Collection
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
		DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp2];
		DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp3];

		WITH 
        acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.policychangenumber,
                acctvpf.AccountTransactionVersionPremiumId,
                acctvpf.Coverage,
				TRIM(REPLACE(REPLACE(acctvpf.[Group],'(Scheduled)',''),'(Blanket)','')) AS class_type,
                CONCAT(
					CASE 
						WHEN acctvpf.[Group] like '%Blanket%' THEN 'blanket'
						WHEN acctvpf.[Group] like '%Scheduled%' THEN 'scheduled'
					END
                    ,'_premium_adjustment'
                ) AS FinalColumnName,
                acctvpf.FactorMethod AS method,
                CONVERT(nvarchar(3000), acctvpf.Factor) AS amount,
                acctvpf.Retention AS [retention],
                acctvpf.Reason AS reason
            FROM [edw_stage].[AccountTransaction] as acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
            INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
            INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
            WHERE acct.[State] = 'ISSUED'
            AND acct.IssuedDate > @last_source_extract_ts
			AND acctvpf.Coverage = 'Collections'
            AND p.[Name] = 'Collections'
            AND p.ProductLine = 'PersonalLines'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, IssuedDate, class_type, policychangenumber, CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, class_type, policychangenumber, CONCAT(FinalColumnName, '_factor') AS FinalColumnName, amount           as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, class_type, policychangenumber, CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, IssuedDate, class_type, policychangenumber, CONCAT(FinalColumnName, '_retention_reason') AS FinalColumnName, reason	as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )

		SELECT
			PolicyNumber, EffectiveDate, IssuedDate, class_type, policychangenumber
			,blanket_premium_adjustment_method
			,blanket_premium_adjustment_factor
			,blanket_premium_adjustment_retention
			,blanket_premium_adjustment_retention_reason
			,scheduled_premium_adjustment_method
			,scheduled_premium_adjustment_factor
			,scheduled_premium_adjustment_retention
			,scheduled_premium_adjustment_retention_reason
		INTO [edw_temp].[tcollection_class_type_temp2]
		FROM acctvpf_unpivot
		PIVOT 
		(
			MAX(FinalValue) FOR FinalColumnName IN (
				blanket_premium_adjustment_method
				,blanket_premium_adjustment_factor
				,blanket_premium_adjustment_retention
				,blanket_premium_adjustment_retention_reason
				,scheduled_premium_adjustment_method
				,scheduled_premium_adjustment_factor
				,scheduled_premium_adjustment_retention
				,scheduled_premium_adjustment_retention_reason
			)
		) AS pvt
        
		SELECT 
			Id, PolicyNumber, EffectiveDate, IssuedDate, ExpirationDate, transaction_dt, PolicyChangeNumber
			,collection_location_sk, policy_history_sk, collection_coverage_sk, home_coverage_sk
			,[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			,class_deleted_in
		FROM
			(
			SELECT
				acctvo.Id, acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.ExpirationDate, acct.TransactionEffectiveDate as transaction_dt, acct.PolicyChangeNumber
				,loc.[collection_location_sk] as [collection_location_sk], his.[policy_history_sk] as [policy_history_sk],
				cov.collection_coverage_sk, hcov.home_coverage_sk
				,acctvof.[Field], acctvof.[Value]
				,acct.CreatedDate, acct.UpdatedDate
				,case when acct.ExternalSourceId is not NULL then 2--(AV2) 
					Else 4 --(Metal)
				end as [source_system_sk] --20230717 added
				,acctvo.IsdeletedOnPolicyChange as class_deleted_in
			INTO [edw_temp].[tcollection_class_type_temp3]
			FROM [edw_stage].[AccountTransaction] as acct
				INNER JOIN [edw_stage].[Product] p on p.Id = acct.ProductId
				INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
				INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
				LEFT JOIN [edw_core].[tcollection_location] loc ON loc.policy_no = acct.PolicyNumber and loc.effective_dt = acct.EffectiveDate
				LEFT JOIN [edw_core].[tcollection_coverage] cov on cov.policy_no = acct.PolicyNumber and cov.effective_dt = acct.EffectiveDate and cov.transaction_seq_no = acct.policychangenumber
				LEFT JOIN [edw_core].[thome_coverage] hcov on hcov.policy_no = acct.PolicyNumber and hcov.effective_dt = acct.EffectiveDate and hcov.transaction_seq_no = acct.policychangenumber
				LEFT JOIN [edw_core].[tpolicy_history] his ON his.policy_no = acct.PolicyNumber AND his.effective_dt=acct.EffectiveDate AND his.transaction_seq_no = acct.policychangenumber
			WHERE acct.[State] = 'ISSUED'
				AND acct.IssuedDate > @last_source_extract_ts
				p.[Name] in ('Collections','Homeowners')
				AND acctvo.ObjectType = 'CollectionClass'
				AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (
					[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
					)
			) pivottable

		SELECT 
            a.*
            ,b.blanket_premium_adjustment_method
			,b.blanket_premium_adjustment_factor
			,b.blanket_premium_adjustment_retention
			,b.blanket_premium_adjustment_retention_reason
			,b.scheduled_premium_adjustment_method
			,b.scheduled_premium_adjustment_factor
			,b.scheduled_premium_adjustment_retention
			,b.scheduled_premium_adjustment_retention_reason
        INTO [edw_temp].[tcollection_class_type_temp1]
        FROM [edw_temp].[tcollection_class_type_temp3] AS a 
        LEFT JOIN [edw_temp].[tcollection_class_type_temp2] AS b
        ON a.PolicyNumber = b.PolicyNumber
        AND a.EffectiveDate = b.EffectiveDate
        AND a.IssuedDate = b.IssuedDate
		AND a.ClassType = b.class_type
        AND a.policychangenumber = b.policychangenumber

			
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
			,[blanket_premium_adjustment_method]
			,[blanket_premium_adjustment_factor]
			,[blanket_premium_adjustment_retention]
			,[blanket_premium_adjustment_retention_reason]
			,[scheduled_premium_adjustment_method]
			,[scheduled_premium_adjustment_factor]
			,[scheduled_premium_adjustment_retention]
			,[scheduled_premium_adjustment_retention_reason]
		)
		SELECT 
			[PolicyNumber]
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
			,[blanket_premium_adjustment_method]
			,[blanket_premium_adjustment_factor]
			,[blanket_premium_adjustment_retention]
			,[blanket_premium_adjustment_retention_reason]
			,[scheduled_premium_adjustment_method]
			,[scheduled_premium_adjustment_factor]
			,[scheduled_premium_adjustment_retention]
			,[scheduled_premium_adjustment_retention_reason]
		FROM 
			[edw_temp].[tcollection_class_type_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.[tcollection_class_type_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp1];
		DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp2];
		DROP TABLE IF EXISTS [edw_temp].[tcollection_class_type_temp3];
		
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

