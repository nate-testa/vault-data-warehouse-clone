-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert nfp policy data in policy claim search api
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/08/23			Mohammed Yunus					1. Created this procedure
-- 02/14/24			Mohammed Yunus					2. Updated transaction_seq_no logic
-- 04-22-2025              Sandeep Gundreddy            3 - Modified update_ts to use cast function 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_nfp_claim_policy_search_api]

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

		DROP TABLE IF EXISTS edw_temp.nfp_claim_policy_search_api_temp1
		-- policy_no, effective_dt, transaction_seq_no, risk_item
		SELECT
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
			insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,source_system_nm,
			row_number()over(partition by  policy_no, effective_dt, transaction_seq_no, cast(risk_item as varchar(max))
			order by policy_no,effective_dt,transaction_seq_no) as rn,update_ts
		INTO edw_temp.nfp_claim_policy_search_api_temp1
		FROM
		(
		SELECT insured_cert_no as policy_no,effective_date as effective_dt,expiration_date as expiration_dt,
		transaction_date as transaction_effective_dt,null as policy_status,CONCAT_WS(' ' , insured_first_name,insured_last_name) insured_nm,
		ROW_NUMBER()OVER(partition by policy_no, insured_cert_no order by transaction_date, reporting_month) as transaction_seq_no,
		null as insured_type,'Vault E&S Insurance Company' as uw_company_nm,'PEL' as product_nm,transaction_type,
		risk_group as risk_item,'NFP' as source_system_nm,update_ts
		
		FROM
			edw_stage.nfp_policy
		WHERE
			insured_cert_no is not null
			
		) as temp
		WHERE
			cast(update_ts as datetime2(7)) > @last_source_extract_ts

		INSERT INTO edw_integration.claim_policy_search_api
		(
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
			insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,source_system_nm,
			create_ts,update_ts,etl_audit_sk
		)		
		SELECT policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
		insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,source_system_nm,
		GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.nfp_claim_policy_search_api_temp1
		WHERE
			rn =1

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_ts) FROM edw_temp.nfp_claim_policy_search_api_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.nfp_claim_policy_search_api_temp1
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