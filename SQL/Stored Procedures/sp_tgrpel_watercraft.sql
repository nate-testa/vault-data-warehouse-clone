-- ================================================================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 2026-03-10
-- Description: This procedures insert grpel watercraft data for policies
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date 			|Author							| Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 03/10/26				Yunus Mohammed					1. Procedure created
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tgrpel_watercraft]

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

		drop table if exists edw_temp.tgrpel_watercraft_temp1

		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,
			[Index],policy_history_sk,source_system_sk,
			IssuedDate,[Year],Make,Model,watercraft_deleted_in,watercraft_unique_id			
		into edw_temp.tgrpel_watercraft_temp1
		from
		(
		select * 
		from
			(
			 
			select
			acct.PolicyNumber,CAST(acct.EffectiveDate AS DATE) AS EffectiveDate,CAST(acct.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acct.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,acctvo.[Index],tph.policy_history_sk,
			acct.policychangenumber AS transaction_seq_no, acct.IssuedDate as TransactionDate,acct.IssuedDate,
			CASE WHEN acct.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			acctvof.Field,acctvof.[Value]
			,CASE WHEN acctvo.IsdeletedOnPolicyChange = 1 OR acctvo.IsDeletedOnRenewal =1 THEN 'Yes' ELSE 'No' END as watercraft_deleted_in,
			acctvo.UniqueId as watercraft_unique_id
			from
				edw_stage.AccountTransaction acct
				inner join edw_stage.Product p on p.Id=acct.ProductId
				inner join edw_stage.AccountTransactionVersion acctv on acct.Id=acctv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject acctvo on acctv.Id=acctvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField acctvof on acctvo.Id=acctvof.VersionObjectId
				left join [edw_core].[tpolicy_history] tph on tph.policy_no=acct.PolicyNumber
						and tph.effective_dt=acct.EffectiveDate
						and tph.transaction_seq_no = acct.policychangenumber
				left join edw_stage.Product pr on acct.ProductId = pr.id
			where
				acct.PolicyNumber is not null and
				acct.[State] ='ISSUED'
				and p.[Name]='Participant Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and acctvo.ObjectType='Watercraft'
				and acctvof.Field IN 
				(
					'Year','Make','Model'			
				)
				and acct.IssuedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN ([Year],Make,Model)
		) as pivottable

		INSERT INTO [edw_core].[tgrpel_watercraft]
		(
			policy_no,effective_dt,transaction_effective_dt,expiration_dt,transaction_dt,transaction_seq_no,policy_history_sk,
			watercraft_no,watercraft_year,watercraft_make,watercraft_model,watercraft_deleted_in,watercraft_unique_id,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			PolicyNumber AS policy_no,EffectiveDate AS effective_dt,TransactionEffectiveDate AS transaction_effective_dt,
			ExpirationDate AS expiration_dt,TransactionDate AS transaction_dt,transaction_seq_no,policy_history_sk,
			[Index] as watercraft_no,[Year] AS watercraft_year,Make AS watercraft_make,Model AS watercraft_model,
			watercraft_deleted_in,watercraft_unique_id,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tgrpel_watercraft_temp1 AS ttpv

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tgrpel_watercraft_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tgrpel_watercraft_temp1
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