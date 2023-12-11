-- =================================================================================================
-- Description: This procedures updates policy_sk and broker_sk, in tclaim_transaction table
---------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 12/08/23			Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_temp].[sp_tclaim_transaction_backfill_4451]

AS
BEGIN
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()

		-- Set last source extract date
		SET @last_source_extract_ts = '20170101'
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_backfill_4451

		SELECT
			tc.claim_sk,tc.policy_sk,tbrk.broker_sk,tcust.customer_sk
		INTO edw_temp.tclaim_transaction_backfill_4451
		FROM
			edw_core.tclaim [tc]
			INNER JOIN edw_core.tclaim_transaction [tctxn] ON [tc].claim_sk = [tctxn].claim_sk
			LEFT JOIN edw_core.tbroker tbrk ON tbrk.broker_id = tc.broker_id
			LEFT JOIN edw_core.tcustomer tcust ON tcust.customer_id = [tc].customer_id

		UPDATE [target]
		SET
			[target].policy_sk = [source].policy_sk,
			[target].broker_sk = [source].broker_sk,
			[target].customer_sk = [source].customer_sk
		FROM
		edw_core.tclaim_transaction [target]
		INNER JOIN edw_temp.tclaim_transaction_backfill_4451 [source] ON [target].claim_sk = [source].claim_sk

		SET @rows_affected=@@ROWCOUNT
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_backfill_4451

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END