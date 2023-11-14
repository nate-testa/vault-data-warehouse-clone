-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 10/20/2023
-- Description: This procedures insert OneShield policy data into policy claim search table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_claim_policy_search_api]

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

		DROP TABLE IF EXISTS edw_temp.os_claim_policy_search_api

		SELECT
		policy_number AS policy_no,policy_effective_date AS effective_dt,policy_expiration_date AS expiration_dt,transaction_effective_dt,
		ROW_NUMBER()OVER(PARTITION BY policy_number ORDER BY transaction_processed_dt) AS transaction_seq_no,NULL AS policy_status,
		 insured_name AS insured_nm,null AS insured_type,company as uw_company_nm,
		 CASE product
			WHEN 'Home' THEN 'Homeowners'
			WHEN 'PEL' THEN 'Excess Liability'
			WHEN 'Collection' THEN 'Collections'
			ELSE product
		END AS product_nm,null AS transaction_type,risk_group AS risk_item,
		 'OS' AS source_system_nm
		INTO edw_temp.os_claim_policy_search_api
		FROM
		edw_stage.OneShieldPolicy
		WHERE
		risk_group is not null

		INSERT INTO edw_integration.claim_policy_search_api
		(
		policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
		insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,source_system_nm,
		create_ts,update_ts,etl_audit_sk
		)
		SELECT
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
			insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,source_system_nm,
			getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		FROM
		edw_temp.os_claim_policy_search_api

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(GETDATE() AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_claim_policy_search_api
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