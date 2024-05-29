-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Coverage
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 09/05/24		Hernando Gonzalez Garcia		1. Created this procedure 
-- 05/14/24		Architha Gudimalla				2. Corrected errors
-- 05/28/24		Yunus Mohammed					3. Added AccountObject.Id instead of Account.Id
-- 05/29/24		Alberto Almario					4. Integrate Premium Adjustments data into EDW - Collection
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_collection_class_type_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_class_type_wip_temp1];

		WITH 
        acct AS (

			SELECT *
			FROM [edw_stage].[Account] AS a
			WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
			AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
			AND a.PolicyNumber IS NOT NULL
        )
        ,acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.CreatedDate, acct.[Number],
                acctvpf.Coverage,
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
            FROM acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountPremium] AS acctvp ON acctvp.AccountId = acct.id
            INNER JOIN [edw_stage].[AccountPremiumFactor] AS acctvpf ON acctvpf.AccountPremiumId = acctvp.id
            WHERE acctvpf.Coverage = 'Collections'
            AND p.[Name] = 'Collections'
            AND p.ProductLine = 'PersonalLines'
        )
        ,acctvpf_unpivot AS (
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_method') AS FinalColumnName, method           as FinalValue FROM acctvpf WHERE method IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_factor') AS FinalColumnName, amount           as FinalValue FROM acctvpf WHERE amount IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_retention') AS FinalColumnName, [retention]   as FinalValue FROM acctvpf WHERE [retention] IS NOT NULL
            UNION ALL
            SELECT PolicyNumber, EffectiveDate, CreatedDate, [Number], CONCAT(FinalColumnName, '_retention_reason') AS FinalColumnName, reason           as FinalValue FROM acctvpf WHERE reason IS NOT NULL
        )
        ,FinalTablePremAdj AS (
            SELECT
                PolicyNumber, EffectiveDate, CreatedDate, [Number]
                ,blanket_premium_adjustment_method
                ,blanket_premium_adjustment_factor
                ,blanket_premium_adjustment_retention
                ,blanket_premium_adjustment_retention_reason
                ,scheduled_premium_adjustment_method
                ,scheduled_premium_adjustment_factor
                ,scheduled_premium_adjustment_retention
                ,scheduled_premium_adjustment_retention_reason
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
        )
		,FinalTable AS (
			SELECT 
				Id, PolicyNumber as quote_no, EffectiveDate, ExpirationDate 
				--,[Number]
				,0 as [Number]
				,quote_collection_location_sk, quote_history_sk, quote_collection_coverage_sk, quote_home_coverage_sk
				,[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
				--,4 as [source_system_sk] --20230717 removed
				,source_system_sk --20230717 added
				,CreatedDate, UpdatedDate
			FROM
				(
				SELECT
					acco.Id, acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.[Number]
					,tqcl.quote_collection_location_sk
					,tqh.quote_history_sk
					,tqcc.quote_collection_coverage_sk
					,tqhc.quote_home_coverage_sk
					,accof.[Field], accof.[Value]
					,acc.CreatedDate, acc.UpdatedDate
					,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
						Else 4 --(Metal)
					end as [source_system_sk] --20230717 added
				FROM
					acct as acc
					INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
					inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
					inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
					LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
							and tqh.effective_dt=acc.EffectiveDate
							and tqh.transaction_seq_no = 0
					LEFT JOIN edw_core.tquote_collection_location tqcl on tqcl.quote_no=acc.PolicyNumber			
					LEFT JOIN edw_core.tquote_collection_coverage tqcc on tqcc.quote_no=acc.PolicyNumber
							and tqcc.effective_dt=acc.EffectiveDate and tqcc.transaction_seq_no = 0
					LEFT JOIN edw_core.tquote_home_coverage tqhc on tqhc.quote_no=acc.PolicyNumber
							and tqhc.effective_dt=acc.EffectiveDate and tqhc.transaction_seq_no = 0
				WHERE
					p.[Name] in ('Collections','Homeowners')
					AND acco.ObjectType = 'CollectionClass'
					AND p.ProductLine='PersonalLines' --20230717 added
				) t
			PIVOT 
				(
					MAX([Value]) FOR [Field] IN (
						[ClassType], [ScheduledCoverage], [ScheduledHighestValueLimit], [BlanketCoverage], [BlanketHighestValue], [BlanketSingleArticleLimit], ScheduledItemAppraisalDate
						)
				) pivottable
		)

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
		INTO [edw_temp].[tquote_collection_class_type_wip_temp1]
        FROM FinalTable AS a 
        LEFT JOIN FinalTablePremAdj AS b
        ON a.quote_no = b.PolicyNumber
        AND a.EffectiveDate = b.EffectiveDate
        -- AND a.CreatedDate = b.CreatedDate
        AND a.[Number] = b.[Number]

			
		MERGE INTO [edw_core].[tquote_collection_class_type] AS TARGET
		USING (
		    SELECT
		        [quote_no],
		        [EffectiveDate] AS effective_dt,
		        [ExpirationDate] AS expiration_dt,
		        [Number] AS transaction_seq_no,
		        [quote_collection_location_sk],
		        [quote_history_sk],
		        [quote_home_coverage_sk],
		        [quote_collection_coverage_sk],
		        [ClassType] AS class_type,
		        [ScheduledCoverage] AS scheduled_limit_amt,
		        [ScheduledHighestValueLimit] AS scheduled_highest_value_limit_amt,
		        [BlanketCoverage] AS blanket_limit_amt,
		        [BlanketHighestValue] AS blanket_highest_value_limit_amt,
		        [BlanketSingleArticleLimit] AS blanket_single_article_limit_amt,
		        [ScheduledItemAppraisalDate] AS highest_value_scheduled_item_appraisal_dt,
		        [source_system_sk],
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
			   	,[blanket_premium_adjustment_method]
				,[blanket_premium_adjustment_factor]
				,[blanket_premium_adjustment_retention]
				,[blanket_premium_adjustment_retention_reason]
				,[scheduled_premium_adjustment_method]
				,[scheduled_premium_adjustment_factor]
				,[scheduled_premium_adjustment_retention]
				,[scheduled_premium_adjustment_retention_reason]
		    FROM
		        [edw_temp].[tquote_collection_class_type_wip_temp1]
				where [ClassType] is not null
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.class_type = SOURCE.class_type

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_collection_location_sk = SOURCE.quote_collection_location_sk,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.quote_home_coverage_sk = SOURCE.quote_home_coverage_sk,
		        TARGET.quote_collection_coverage_sk = SOURCE.quote_collection_coverage_sk,
		        TARGET.scheduled_limit_amt = SOURCE.scheduled_limit_amt,
		        TARGET.scheduled_highest_value_limit_amt = SOURCE.scheduled_highest_value_limit_amt,
		        TARGET.blanket_limit_amt = SOURCE.blanket_limit_amt,
		        TARGET.blanket_highest_value_limit_amt = SOURCE.blanket_highest_value_limit_amt,
		        TARGET.blanket_single_article_limit_amt = SOURCE.blanket_single_article_limit_amt,
		        TARGET.highest_value_scheduled_item_appraisal_dt = SOURCE.highest_value_scheduled_item_appraisal_dt,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
				TARGET.blanket_premium_adjustment_method = SOURCE.blanket_premium_adjustment_method,
				TARGET.blanket_premium_adjustment_factor = SOURCE.blanket_premium_adjustment_factor,
				TARGET.blanket_premium_adjustment_retention = SOURCE.blanket_premium_adjustment_retention,
				TARGET.blanket_premium_adjustment_retention_reason = SOURCE.blanket_premium_adjustment_retention_reason,
				TARGET.scheduled_premium_adjustment_method = SOURCE.scheduled_premium_adjustment_method,
				TARGET.scheduled_premium_adjustment_factor = SOURCE.scheduled_premium_adjustment_factor,
				TARGET.scheduled_premium_adjustment_retention = SOURCE.scheduled_premium_adjustment_retention,
				TARGET.scheduled_premium_adjustment_retention_reason = SOURCE.scheduled_premium_adjustment_retention_reason

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no,
		        effective_dt,
		        expiration_dt,
		        transaction_seq_no,
		        quote_collection_location_sk,
		        quote_history_sk,
		        quote_home_coverage_sk,
		        quote_collection_coverage_sk,
		        class_type,
		        scheduled_limit_amt,
		        scheduled_highest_value_limit_amt,
		        blanket_limit_amt,
		        blanket_highest_value_limit_amt,
		        blanket_single_article_limit_amt,
		        highest_value_scheduled_item_appraisal_dt,
		        source_system_sk,
		        create_ts,
		        update_ts,
		        etl_audit_sk
				,[blanket_premium_adjustment_method]
				,[blanket_premium_adjustment_factor]
				,[blanket_premium_adjustment_retention]
				,[blanket_premium_adjustment_retention_reason]
				,[scheduled_premium_adjustment_method]
				,[scheduled_premium_adjustment_factor]
				,[scheduled_premium_adjustment_retention]
				,[scheduled_premium_adjustment_retention_reason]
		    )
		    VALUES (
		        SOURCE.quote_no,
		        SOURCE.effective_dt,
		        SOURCE.expiration_dt,
		        SOURCE.transaction_seq_no,
		        SOURCE.quote_collection_location_sk,
		        SOURCE.quote_history_sk,
		        SOURCE.quote_home_coverage_sk,
		        SOURCE.quote_collection_coverage_sk,
		        SOURCE.class_type,
		        SOURCE.scheduled_limit_amt,
		        SOURCE.scheduled_highest_value_limit_amt,
		        SOURCE.blanket_limit_amt,
		        SOURCE.blanket_highest_value_limit_amt,
		        SOURCE.blanket_single_article_limit_amt,
		        SOURCE.highest_value_scheduled_item_appraisal_dt,
		        SOURCE.source_system_sk,
		        SOURCE.create_ts,
		        SOURCE.update_ts,
		        SOURCE.etl_audit_sk
				,SOURCE.[blanket_premium_adjustment_method]
				,SOURCE.[blanket_premium_adjustment_factor]
				,SOURCE.[blanket_premium_adjustment_retention]
				,SOURCE.[blanket_premium_adjustment_retention_reason]
				,SOURCE.[scheduled_premium_adjustment_method]
				,SOURCE.[scheduled_premium_adjustment_factor]
				,SOURCE.[scheduled_premium_adjustment_retention]
				,SOURCE.[scheduled_premium_adjustment_retention_reason]
		);

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.[tquote_collection_class_type_wip_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_collection_class_type_wip_temp1];
		
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

GO
