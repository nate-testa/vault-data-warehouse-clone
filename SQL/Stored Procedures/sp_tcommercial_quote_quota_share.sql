SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-19
-- Description: This stored procedure insert and update info related to tcommercial_quote_quota_share.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 19/03/2025           Alberto Almario				1. Created this procedure 
-- 22/04/2025           Alberto Almario				2. Change PolicyNumber to Number from Account table
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_quota_share]
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
        
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp3;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp4;

		-- Step1 limit amount of rows.

		SELECT 
			 acct.Id
			,acct.AccountId
			,CAST(acc.Number AS VARCHAR(255)) as quote_no
			,acct.EffectiveDate
			,acct.ExpirationDate
			,acct.Number as transaction_seq_no
			,CASE 
				WHEN acct.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
				ELSE 4 --(Metal)
			 END source_system_sk
			,DENSE_RANK()OVER(PARTITION BY acc.Number,CAST(acct.EffectiveDate AS DATE) ORDER BY acct.Number DESC) AS rnk
			,acct.CreatedDate
		INTO edw_temp.tcommercial_quote_quota_share_temp1 
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.Account acc ON acct.AccountId = acc.Id
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id
		INNER JOIN edw_stage.AccountTransactionVersionPremium acctvp ON acctvp.AccountTransactionVersionId = acctv.Id 
		LEFT JOIN edw_stage.Product pr on acctv.ProductId = pr.id
		WHERE acct.Stage in ('QUOTE','POLICY')
		AND pr.ProductLine = 'CommercialLines'
		AND acct.CreatedDate > @last_source_extract_ts

		-- Pivot Table
		SELECT	
			 AccountTransactionId
			,ParentObjectId
			,CASE WHEN [UniqueId] IS NULL OR [UniqueId] = '00000000-0000-0000-0000-000000000000' THEN cast([Index] as varchar(255)) ELSE cast([UniqueId] as varchar(255)) END as quota_share_unique_id
			,nullif(trim(CompanyName),'') as company_nm
			,nullif(trim(PolicyNumber),'') as company_policy_no
			,nullif(trim(QuotaShare),'') as quota_share_pc
			,nullif(trim(LimitPerClaim),'') as per_claim_policy_limit_amt
			,nullif(trim(LimitPerAggregate),'') as aggregate_policy_limit_amt
		INTO edw_temp.tcommercial_quote_quota_share_temp2
		FROM
			(
				SELECT  
					 acctv.AccountTransactionId
					,acctvo.ParentObjectId
					,acctvo.[UniqueId]
					,acctvo.[Index]
					,acctvof.Field
					,nullif(acctvof.Value,'NaN') as [Value]
				FROM edw_temp.tcommercial_quote_quota_share_temp1 acc
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id
				INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE acctvo.ObjectType in ('TowerquotaShare')
				AND acctvo.ParentObjectId IS NOT NULL
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					CompanyName, PolicyNumber, QuotaShare, LimitPerClaim, LimitPerAggregate
					)
			) pivottable 
		
		--Create temp table 3
		SELECT  
			acctv.AccountTransactionId
			,acctvo.Id as ObjectId
			,acctvo.[UniqueId]
			,acctvo.[Index]
			,CASE WHEN acctvo.[UniqueId] IS NULL OR acctvo.[UniqueId] = '00000000-0000-0000-0000-000000000000' THEN cast(acctvo.[Index] as varchar(255)) ELSE cast(acctvo.[UniqueId] as varchar(255)) END as tower_unique_id
		INTO edw_temp.tcommercial_quote_quota_share_temp3
		FROM edw_temp.tcommercial_quote_quota_share_temp1 acc
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id
		INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
		WHERE acctvo.ObjectType in ('Tower')

		-- Create final table
		SELECT 
			 tmp1.quote_no
			,tmp1.EffectiveDate as effective_dt
			,tmp1.ExpirationDate as expiration_dt			
			,tmp1.transaction_seq_no
			,cq.commercial_quote_history_sk
			,cqt.commercial_quote_tower_sk
			,tmp2.quota_share_unique_id
			,tmp2.company_nm
			,tmp2.company_policy_no
			,tmp2.quota_share_pc
			,tmp2.per_claim_policy_limit_amt
			,tmp2.aggregate_policy_limit_amt
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,tmp1.source_system_sk
		INTO edw_temp.tcommercial_quote_quota_share_temp4
		FROM edw_temp.tcommercial_quote_quota_share_temp1 tmp1
		INNER JOIN edw_temp.tcommercial_quote_quota_share_temp2 tmp2 on tmp2.AccountTransactionId = tmp1.Id
		LEFT JOIN edw_temp.tcommercial_quote_quota_share_temp3 tmp3 on tmp3.AccountTransactionId = tmp1.Id and tmp3.ObjectId = tmp2.ParentObjectId
		LEFT JOIN edw_commercial.tcommercial_quote_history cq on tmp1.quote_no = cq.quote_no and cast(tmp1.EffectiveDate as date) = cast(cq.effective_dt as date) and tmp1.transaction_seq_no = cq.transaction_seq_no
		LEFT JOIN edw_commercial.tcommercial_quote_tower cqt on tmp1.quote_no = cqt.quote_no and cast(tmp1.EffectiveDate as date) = cast(cqt.effective_dt as date) and tmp1.transaction_seq_no = cqt.transaction_seq_no and tmp3.tower_unique_id = cqt.tower_unique_id

		-- Insert process
		INSERT INTO edw_commercial.tcommercial_quote_quota_share
		 (
			 quote_no
			,effective_dt
			,expiration_dt
			,transaction_seq_no
			,commercial_quote_history_sk
			,commercial_quote_tower_sk
			,quota_share_unique_id
			,company_nm
			,company_policy_no
			,quota_share_pc
			,per_claim_policy_limit_amt
			,aggregate_policy_limit_amt
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
			)
		SELECT
			quote_no
			,effective_dt
			,expiration_dt
			,transaction_seq_no
			,commercial_quote_history_sk
			,commercial_quote_tower_sk
			,quota_share_unique_id
			,company_nm
			,company_policy_no
			,quota_share_pc
			,per_claim_policy_limit_amt
			,aggregate_policy_limit_amt
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
		FROM edw_temp.tcommercial_quote_quota_share_temp4	
		;

        --************End************

		SET @rows_affected=@@ROWCOUNT;


		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.[tcommercial_quote_quota_share_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp3;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_quota_share_temp4;

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
