SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Item Detail 
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 23/10/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_collection_scheduled_item]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_scheduled_item_temp1];
		SELECT 
			Id,
			PolicyNumber as quote_no,
			EffectiveDate,
			ExpirationDate,
			[Number],
			[quote_history_sk],
			[quote_collection_class_type_sk],
			[Index] as scheduled_item_no,
			[Description], [CoverageLimit], [SeeScheduleOnFileWithTheCompany], AppraisalDate, CollectorCar,
			--4 as [source_system_sk], --20230717 removed
			source_system_sk, --20230717 added
			CreatedDate,
			UpdatedDate
		INTO [edw_temp].[tquote_collection_scheduled_item_temp1]
		FROM
			(
			SELECT
				acct.Id,
				acc.PolicyNumber, acc.EffectiveDate,acc.ExpirationDate, acc.[Number]
				,tqh.[quote_history_sk]
				,tqcct.[quote_collection_class_type_sk]
				,acct.[Index]
				,accto.Field, accto.[Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(SELECT
					acct.*
					--,ROW_NUMBER() OVER (PARTITION BY acct.PolicyNumber, acct.EffectiveDate ORDER BY acct.number DESC) AS AccountTransaction_Rank
				FROM [edw_stage].[AccountTransaction] acct
				WHERE
					acct.[Stage] IN ('QUOTE','POLICY')
					--AND GREATEST(CreatedDate)>@last_source_extract_ts --20230717 removed
					AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] pid ON pid.versionobjectid = acct.parentobjectid and pid.Field = 'ClassType'
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = acc.number
				LEFT JOIN edw_core.tquote_collection_class_type tqcct 
						on tqcct.quote_no=acc.PolicyNumber
						and tqcct.effective_dt=acc.EffectiveDate
			WHERE
				p.[Name] in ('Collections','Homeowners')
				AND acct.ObjectType = 'CollectionClassScheduleItem'
				AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR[Field] IN (
					[Description], [CoverageLimit], [SeeScheduleOnFileWithTheCompany], [AppraisalDate], [CollectorCar]
					)
			) pivottable

		-- Start Insert process
		INSERT INTO [edw_core].[tquote_collection_scheduled_item] (
			[quote_no]
           ,[effective_dt]
           ,[expiration_dt]
           ,[transaction_seq_no]
           ,[quote_history_sk]
           ,[quote_collection_class_type_sk]
		   ,[scheduled_item_no]
           ,[item_desc]
           ,[coverage_limit_amt]
           ,[schedule_on_file_in]
           ,[appraisal_dt]
		   ,[collector_car_in]
           ,[source_system_sk]
           ,[create_ts]
           ,[update_ts]
           ,[etl_audit_sk]
			)
		SELECT 
			[quote_no],[EffectiveDate],[ExpirationDate],[Number]
			,[quote_history_sk],[quote_collection_class_type_sk]
			,[scheduled_item_no]
			,[Description],[CoverageLimit],[SeeScheduleOnFileWithTheCompany],[AppraisalDate],[CollectorCar]
			,[source_system_sk],getdate(),getdate(), @etl_audit_sk
		FROM 
			[edw_temp].[tquote_collection_scheduled_item_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM [edw_temp].[tquote_collection_scheduled_item_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_collection_scheduled_item_temp1];
		
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