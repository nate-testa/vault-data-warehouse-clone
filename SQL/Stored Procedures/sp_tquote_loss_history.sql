SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ================================================================================================= 
-- Author:		Hernando Gonzalez Garcia
-- Create Date: <Create Date, , >
-- Description: This procedures insert and update info related to Loss History
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 01-15-2025				Alberto Almario				1. Add include_in_rating_in column.
-- 02-05-2025				Alberto Almario				2. Add new columns source_of_water, source_of_fire and include_in_rating_override_in..
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_loss_history]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_loss_history_temp1];
		SELECT 
			PolicyNumber as quote_no, EffectiveDate, ExpirationDate, Number
			,quote_history_sk
			,[index] as loss_seq_no
			,PropertyOrLiability, [Source] as source_nm, ClaimStatus, Claimant, FileNumber, LossDate, LossIdentifier, LossType, 
			SubCauseofLoss as sub_cause_of_loss, LossDescription, PolicyType, CatIndicator, Disputed,
			AddressLine1, AddressLine2, AddressLineUnit, AddressCity, AddressState, AddressZipCode, Coverage,
			ReserveIndemnity, ReserveExpense, PaidIndemnity, PaidExpense, TotalIncurred, IncludeInRating
			,SourceOfWater, SourceOfFire, IncludeInRatingOverride
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
		INTO [edw_temp].[tquote_loss_history_temp1]
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.IssuedDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, acc.Number
				,tqh.quote_history_sk as [quote_history_sk]
				,acct.[Index]
				,accto.[Field], NULLIF(accto.[Value], '') as [Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(SELECT
					*
				FROM [edw_stage].[AccountTransaction]
				WHERE
					[Stage] IN ('QUOTE','POLICY')	
					AND CreatedDate>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = acc.number
			WHERE
				--p.[Name]='Collections'
				acct.ObjectType = 'LossHistory'
				--AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (
					PropertyOrLiability, [Source], ClaimStatus, Claimant, FileNumber, LossDate, LossIdentifier, LossType, SubCauseofLoss, 
					LossDescription, PolicyType, CatIndicator, Disputed, AddressLine1, AddressLine2, AddressLineUnit, AddressCity, AddressState, AddressZipCode, 
					Coverage, ReserveIndemnity, ReserveExpense, PaidIndemnity, PaidExpense, TotalIncurred, IncludeInRating
					,SourceOfWater, SourceOfFire, IncludeInRatingOverride
					)
			) pivottable
			
		-- Start Insert process
		INSERT INTO [edw_core].[tquote_loss_history] (
			[quote_no]
			,[effective_dt]
			,[expiration_dt]
			,[transaction_seq_no]
			,[quote_history_sk]
			,[loss_seq_no]
			,[property_or_liability]
			,[source_nm]
			,[claim_status]
			,[claimant_nm]
			,[file_no]
			,[loss_dt]
			,[loss_indentifier]
			,[type_of_loss]
			,[sub_cause_of_loss_desc]
			,[loss_desc]
			,[policy_type]
			,[cat_loss_in]
			,[disputed_in]
			,[loss_address_line_1]
			,[loss_address_line_2]
			,[loss_address_unit_no]
			,[loss_address_city_nm]
			,[loss_address_state_cd]
			,[loss_address_zip_cd]
			,[coverage_desc]
			,[indemnity_reserve_amt]
			,[expense_reserve_amt]
			,[indemnity_paid_amt]
			,[expense_paid_amt]
			,[total_incurred_amt]
			,[source_system_sk]
			,[create_ts]
			,[update_ts]
			,[etl_audit_sk]
			,include_in_rating_in
			,source_of_water
			,source_of_fire
			,include_in_rating_override_in
		)
		SELECT 
			[quote_no]
			,[EffectiveDate]
			,[ExpirationDate]
			,[Number]
			,[quote_history_sk]
			,[loss_seq_no]
			,[PropertyOrLiability]
			,[Source_nm]
			,[ClaimStatus]
			,[Claimant]
			,[FileNumber]
			,[LossDate]
			,[LossIdentifier]
			,[LossType]
			,[sub_cause_of_loss]
			,[LossDescription]
			,[PolicyType]
			,[CatIndicator]
			,[Disputed]
			,[AddressLine1]
			,[AddressLine2]
			,[AddressLineUnit]
			,[AddressCity]
			,[AddressState]
			,[AddressZipCode]
			,[Coverage]
			,[ReserveIndemnity]
			,[ReserveExpense]
			,[PaidIndemnity]
			,[PaidExpense]
			,[TotalIncurred]
			,[source_system_sk]
			,getdate()
			,getdate()
			,@etl_audit_sk
			,CASE 
				WHEN IncludeInRating = 'true' THEN 'Yes'
				WHEN IncludeInRating = 'false' THEN 'No'
				ELSE IncludeInRating
			END
			,SourceOfWater
			,SourceOfFire
			,CASE 
				WHEN IncludeInRatingOverride = 'true' THEN 'Yes'
				WHEN IncludeInRatingOverride = 'false' THEN 'No'
				ELSE IncludeInRatingOverride
			END
		FROM 
			[edw_temp].[tquote_loss_history_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM edw_temp.[tquote_loss_history_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_loss_history_temp1];
		
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