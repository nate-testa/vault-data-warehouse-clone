-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Item Detail 
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 09/05/24		Hernando Gonzalez Garcia		1. Created this procedure 
-- 05/14/24		Architha Gudimalla				3. Corrected errors
-- 05/30/24		Yunus Mohammed					3. Added AccountObject.Id instead of Account.Id
-- 22/08/24		Hernando Gonzalez				4. Remove effective date from the merge join
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_collection_scheduled_item_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_scheduled_item_wip_temp1];
		SELECT 
			Id,
			PolicyNumber as quote_no,
			EffectiveDate,
			ExpirationDate,
			--[Number],
			0 as [Number],
			[quote_history_sk],
			[quote_collection_class_type_sk],
			[Index] as scheduled_item_no,
			[Description], [CoverageLimit], [SeeScheduleOnFileWithTheCompany], AppraisalDate, CollectorCar,
			--4 as [source_system_sk], --20230717 removed
			source_system_sk, --20230717 added
			CreatedDate,
			UpdatedDate
		INTO [edw_temp].[tquote_collection_scheduled_item_wip_temp1]
		FROM
			(
			SELECT
				acco.Id,
				acc.PolicyNumber, acc.EffectiveDate,acc.ExpirationDate, acc.[Number]
				,tqh.[quote_history_sk]
				,tqcct.[quote_collection_class_type_sk]
				,acco.[Index]
				,accof.Field, accof.[Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				LEFT JOIN [edw_stage].[AccountObjectField] pid ON pid.objectid = acco.parentobjectid and pid.Field = 'ClassType'
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
				LEFT JOIN edw_core.tquote_collection_class_type tqcct 
						on tqcct.quote_no=acc.PolicyNumber
						and tqcct.effective_dt=acc.EffectiveDate
						and tqcct.transaction_seq_no = 0 and pid.value = tqcct.class_type 
			WHERE
				p.[Name] in ('Collections','Homeowners')
				AND acco.ObjectType = 'CollectionClassScheduleItem'
				AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR[Field] IN (
					[Description], [CoverageLimit], [SeeScheduleOnFileWithTheCompany], [AppraisalDate], [CollectorCar]
					)
			) pivottable

		MERGE INTO [edw_core].[tquote_collection_scheduled_item] AS TARGET
		USING (
		    SELECT 
		        [quote_no],
		        [EffectiveDate] AS effective_dt,
		        [ExpirationDate] AS expiration_dt,
		        [Number] AS transaction_seq_no,
		        [quote_history_sk],
		        [quote_collection_class_type_sk],
		        [scheduled_item_no],
		        [Description] AS item_desc,
		        [CoverageLimit] AS coverage_limit_amt,
		        [SeeScheduleOnFileWithTheCompany] AS schedule_on_file_in,
		        [AppraisalDate] AS appraisal_dt,
		        [CollectorCar] AS collector_car_in,
		        [source_system_sk],
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
		    FROM 
		        [edw_temp].[tquote_collection_scheduled_item_wip_temp1]
		) AS SOURCE
		ON 
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.expiration_dt = SOURCE.expiration_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.quote_collection_class_type_sk = SOURCE.quote_collection_class_type_sk AND
		    TARGET.scheduled_item_no = SOURCE.scheduled_item_no 
		   -- TARGET.quote_history_sk = SOURCE.quote_history_sk
		WHEN MATCHED THEN
		    UPDATE SET
				TARGET.effective_dt = SOURCE.effective_dt,
		        --TARGET.scheduled_item_no = SOURCE.scheduled_item_no,
		        TARGET.item_desc = SOURCE.item_desc,
		        TARGET.coverage_limit_amt = SOURCE.coverage_limit_amt,
		        TARGET.schedule_on_file_in = SOURCE.schedule_on_file_in,
		        TARGET.appraisal_dt = SOURCE.appraisal_dt,
		        TARGET.collector_car_in = SOURCE.collector_car_in,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.create_ts = SOURCE.create_ts,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk
		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no,
		        effective_dt,
		        expiration_dt,
		        transaction_seq_no,
		        quote_history_sk,
		        quote_collection_class_type_sk,
		        scheduled_item_no,
		        item_desc,
		        coverage_limit_amt,
		        schedule_on_file_in,
		        appraisal_dt,
		        collector_car_in,
		        source_system_sk,
		        create_ts,
		        update_ts,
		        etl_audit_sk
		    )
		    VALUES (
		        SOURCE.quote_no,
		        SOURCE.effective_dt,
		        SOURCE.expiration_dt,
		        SOURCE.transaction_seq_no,
		        SOURCE.quote_history_sk,
		        SOURCE.quote_collection_class_type_sk,
		        SOURCE.scheduled_item_no,
		        SOURCE.item_desc,
		        SOURCE.coverage_limit_amt,
		        SOURCE.schedule_on_file_in,
		        SOURCE.appraisal_dt,
		        SOURCE.collector_car_in,
		        SOURCE.source_system_sk,
		        SOURCE.create_ts,
		        SOURCE.update_ts,
		        SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM [edw_temp].[tquote_collection_scheduled_item_wip_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_collection_scheduled_item_wip_temp1];
		
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

GO