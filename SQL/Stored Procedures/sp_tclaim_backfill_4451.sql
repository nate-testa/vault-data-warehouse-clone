-- =================================================================================================
-- Description: This procedures updates broker_id in tclaim table
---------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 12/08/23			Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_temp].[sp_tclaim_backfill_4451]

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

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

		DROP TABLE IF EXISTS edw_temp.tclaim_backfill_4451

		SELECT
			[target].claim_no,[source].broker_id, [source].customer_id
		INTO edw_temp.tclaim_backfill_4451
		FROM
		edw_core.tclaim [target]
		INNER JOIN 
		(
			SELECT
			claim_no, broker_id, customer_id
			FROM
			(
			SELECT
				ROW_NUMBER() OVER(PARTITION BY tcase.claim_no,tph.policy_no ORDER BY tph.transaction_seq_no DESC) AS rn,
				tbrk.broker_id,
				tcase.claim_no,
				tcust.customer_id
			FROM
				edw_stage.t_clm_case tcase
				LEFT JOIN edw_core.tpolicy_history tph ON TRIM(tcase.policy_no) = tph.policy_no
				AND tph.policy_history_sk = (
									SELECT TOP 1 policy_history_sk
									FROM
										edw_core.tpolicy_history tph1
									WHERE
										tph1.policy_no = tcase.policy_no
										AND CAST(tph1.transaction_effective_dt AS DATE) <= CAST(tcase.accident_time AS DATE)
									ORDER BY transaction_seq_no DESC
									)
				LEFT JOIN edw_core.tbroker tbrk ON tbrk.broker_sk = tph.broker_sk
				LEFT JOIN edw_core.tcustomer tcust ON tcust.customer_sk = tph.customer_sk
			WHERE tcase.update_time>@last_source_extract_ts
			) AS t
		WHERE
			rn=1
		) AS [source] ON [target].claim_no = [source].claim_no

        UPDATE [target]
		SET
			[target].broker_id = [source].broker_id,
			[target].customer_id = [source].customer_id
		FROM
		edw_core.tclaim [target]
		INNER JOIN edw_temp.tclaim_backfill_4451 [source] ON [target].claim_no = [source].claim_no

		SET @rows_affected=@@ROWCOUNT;
        DROP TABLE IF EXISTS edw_temp.tclaim_backfill_4451
		
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