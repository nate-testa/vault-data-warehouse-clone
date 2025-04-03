SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-19
-- Description: This stored procedure insert and update info related to tcommercial_policy_subjectivity.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 19/03/2025           Alberto Almario				1. Created this procedure 
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_policy_subjectivity]
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
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))


		--************Start************
        
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_subjectivity_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_subjectivity_temp2;

		-- Step1 limit amount of rows.
		SELECT 
			 acct.Id
			,acct.AccountId
			,acct.PolicyNumber
			,acct.EffectiveDate
			,acct.ExpirationDate
			,acct.TransactionEffectiveDate
			,acct.PolicyChangeNumber
			,CASE 
				WHEN acct.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
				ELSE 4 --(Metal)
			 END source_system_sk
			,DENSE_RANK()OVER(PARTITION BY acct.PolicyNumber,CAST(acct.EffectiveDate AS DATE) ORDER BY acct.policychangenumber DESC) AS rnk
			,IssuedDate
		INTO edw_temp.tcommercial_policy_subjectivity_temp1 
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.Account acc ON acct.AccountId = acc.Id
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id 
		INNER JOIN edw_stage.AccountTransactionVersionPremium acctvp ON acctvp.AccountTransactionVersionId = acctv.Id
		LEFT JOIN edw_stage.Product pr on acctv.ProductId = pr.id
		WHERE acct.State ='ISSUED'
		AND	acct.PolicyNumber IS NOT NULL 
		AND pr.ProductLine = 'CommercialLines'
		AND acct.IssuedDate > @last_source_extract_ts

		-- Pivot Table
		SELECT	
			 AccountTransactionId
			,RequieredFor
			,DescriptionText
			,CompletedIn
		INTO edw_temp.tcommercial_policy_subjectivity_temp2
		FROM
			(
				SELECT  
					 acctv.AccountTransactionId
					,acctvof.Field
					,acctvof.Value
				FROM edw_temp.tcommercial_policy_subjectivity_temp1 acc
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id
				INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE acctvo.ObjectType in ('Tower')
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					RequieredFor,DescriptionText,CompletedIn
					)
			) pivottable 

		-- Insert process
		INSERT INTO edw_commercial.tcommercial_policy_subjectivity
		(
			 policy_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,commercial_policy_history_sk
			,required_for
			,[description]
			,completed_in
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
			)
		SELECT 
			 tmp1.PolicyNumber as policy_no
			,tmp1.EffectiveDate as effective_dt
			,tmp1.ExpirationDate as expiration_dt
			,tmp1.TransactionEffectiveDate as transaction_effective_dt
			,tmp1.PolicyChangeNumber as transaction_seq_no
			,cp.commercial_policy_history_sk
			,'pending' as required_for
			,'pending' as [description]
			,'pending' as completed_in
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,tmp1.source_system_sk
		FROM edw_temp.tcommercial_policy_subjectivity_temp1 tmp1
		LEFT JOIN edw_temp.tcommercial_policy_subjectivity_temp2 tmp2 on tmp2.AccountTransactionId = tmp1.Id
		LEFT JOIN edw_commercial.tcommercial_policy_history cp on tmp1.PolicyNumber = cp.policy_no and cast(tmp1.EffectiveDate as date) = cast(cp.effective_dt as date) and tmp1.PolicyChangeNumber = cp.transaction_seq_no
		;

        --************End************

		SET @rows_affected=@@ROWCOUNT;


		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tcommercial_policy_subjectivity_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_subjectivity_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_subjectivity_temp2;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	
    END CATCH
END
