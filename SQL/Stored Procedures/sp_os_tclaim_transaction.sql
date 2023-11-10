-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShield claim transaction into tclaim transaction table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tclaim_transaction]

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

		DROP TABLE IF EXISTS edw_temp.os_tclaim_transaction_temp1

		SELECT
		tcf.claim_sk, tcf.claim_feature_sk,temptrans.product_sk,temptrans.defense_cost_in,temptrans.transaction_date_sk as transaction_dt_sk,
		temptrans.transaction_ts,NULL AS claim_payment_sk,temptrans.claim_transaction_type_sk AS claim_transaction_type_sk,
		temptrans.feature_status_sk,
		ROUND(temptrans.loss_reserve_amt,2) AS loss_reserve_amt,ROUND(temptrans.expense_reserve_amt,2) AS expense_reserve_amt,
		ROUND(temptrans.adjusting_other_reserve_amt,2) AS adjusting_other_reserve_amt,ROUND(temptrans.subro_reserve_amt,2) AS subro_reserve_amt,
		ROUND(temptrans.salvage_reserve_amt,2) AS salvage_reserve_amt,ROUND(temptrans.salvage_expense_reserve_amt,2) AS salvage_expense_reserve_amt,
		ROUND(temptrans.subro_expense_reserve_amt,2) AS subro_expense_reserve_amt,ROUND(temptrans.loss_paid_amt,2) AS loss_paid_amt,
		ROUND(temptrans.expense_paid_amt,2) AS expense_paid_amt,ROUND(temptrans.adjusting_other_paid_amt,2) AS adjusting_other_paid_amt,
		ROUND(temptrans.subro_recovery_amt,2) AS subro_recovery_amt,ROUND(temptrans.salvage_recovery_amt,2) AS salvage_recovery_amt,
		ROUND(temptrans.salvage_expense_paid_amt,2) AS salvage_expense_paid_amt,ROUND(temptrans.subro_expense_paid_amt,2) AS subro_expense_paid_amt,
		ROUND(temptrans.refund_indemnity_paid_amt,2) AS refund_indemnity_paid_amt,ROUND(temptrans.refund_expense_paid_amt,2) AS refund_expense_paid_amt,
		temptrans.source_system_sk
		INTO edw_temp.os_tclaim_transaction_temp1
		FROM
		edw_stage.dragon_claim_transaction_os temptrans
		INNER JOIN (
		SELECT
		tc.claim_sk,
		RIGHT('000'+ CAST(ROW_NUMBER()OVER(PARTITION BY ttcf.claim_no ORDER BY tc.claim_sk,ttcf.claim_coverage_cd) AS VARCHAR(100)),3) AS subclaim_seq_no,
		ttcf.join_key
		FROM
		edw_stage.dragon_feature_os ttcf
		INNER JOIN edw_core.tclaim tc ON ttcf.claim_no=tc.claim_no
		WHERE
		tc.source_system_sk=1
		) AS temp ON temp.join_key=temptrans.join_key
		INNER JOIN edw_core.tclaim_feature tcf ON temp.claim_sk=tcf.claim_sk
		AND temp.subclaim_seq_no=tcf.subclaim_seq_no


		INSERT INTO edw_core.tclaim_transaction
		(
		claim_sk,claim_feature_sk,product_sk,defense_cost_in,transaction_dt_sk,transaction_ts,
		claim_payment_sk,claim_transaction_type_sk,feature_status_sk,
		loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,
		adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
		refund_indemnity_paid_amt,refund_expense_paid_amt,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT claim_sk,claim_feature_sk,product_sk,defense_cost_in,transaction_dt_sk,transaction_ts,
		claim_payment_sk,claim_transaction_type_sk,feature_status_sk,
		loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,
		adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
		refund_indemnity_paid_amt,refund_expense_paid_amt,source_system_sk,
		GETDATE() AS create_ts,GETDATE() AS update_ts, @etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tclaim_transaction_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_transaction_temp1
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