-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedure calculate claim amounts at claim level
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 09/28/2023	Mohammed Yunus					1. Procedure created
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_summary]
@start_month int,
@end_month int
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
	DECLARE @etl_audit_sk INT
	DECLARE @begin_dt_sk INT
	DECLARE @end_dt_sk INT
	DECLARE @rows_affected INT
	DECLARE @procedure_sk INT, @procedure_nm VARCHAR(255)
	DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
	DECLARE @current_date DATETIME=GETDATE()
	DECLARE @parameter_desc VARCHAR(255)
	DECLARE @last_source_extract_ts DATETIME2(7)
	DECLARE @new_last_source_extract_ts DATETIME2(7)

	DECLARE cur_main CURSOR FOR
	SELECT MIN(date_sk) AS begin_dt_sk, MAX(date_sk) AS end_dt_sk
	FROM edw_core.tdate
	WHERE yearmonth BETWEEN @start_month AND @end_month
	GROUP BY yearmonth
	ORDER BY yearmonth

	OPEN cur_main
	FETCH NEXT FROM cur_main INTO @begin_dt_sk,@end_dt_sk

	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		
		DELETE FROM edw_core.tclaim_summary WHERE month_sk=@end_dt_sk

		INSERT INTO edw_core.tclaim_summary
		(
			month_sk,claim_sk,product_sk,policy_sk,broker_sk,customer_sk,
			loss_reserve_amt,itd_loss_reserve_amt, expense_reserve_amt,itd_expense_reserve_amt, 
			adjusting_other_reserve_amt, itd_adjusting_other_reserve_amt,
			subro_reserve_amt,itd_subro_reserve_amt, salvage_reserve_amt, itd_salvage_reserve_amt,
			salvage_expense_reserve_amt,itd_salvage_expense_reserve_amt,
			subro_expense_reserve_amt,itd_subro_expense_reserve_amt,
			loss_paid_amt,itd_loss_paid_amt,
			expense_paid_amt,itd_expense_paid_amt,
			adjusting_other_paid_amt,itd_adjusting_other_paid_amt,
			subro_recovery_amt,itd_subro_recovery_amt,
			salvage_recovery_amt,itd_salvage_recovery_amt,
			salvage_expense_paid_amt,itd_salvage_expense_paid_amt,
			subro_expense_paid_amt,itd_subro_expense_paid_amt,
			refund_indemnity_paid_amt,itd_refund_indemnity_paid_amt, 
			refund_expense_paid_amt,itd_refund_expense_paid_amt,
			dcc_expense_paid_amt,
			open_claim_ct,closed_claim_ct,
			itd_refund_paid_amt,itd_total_incurred_amt,itd_total_paid_amt,itd_total_reserve_amt,
			itd_dcc_expense_paid_amt,source_system_sk,update_ts,etl_audit_sk
		)
		SELECT
		@end_dt_sk AS month_sk, claim_sk,product_sk,policy_sk,broker_sk,customer_sk,
		SUM(loss_reserve_amt) AS loss_reserve_amt,SUM(itd_loss_reserve_amt) AS itd_loss_reserve_amt,
		SUM(expense_reserve_amt) AS expense_reserve_amt,SUM(itd_expense_reserve_amt) AS itd_expense_reserve_amt,
		SUM(adjusting_other_reserve_amt) AS adjusting_other_reserve_amt,SUM(itd_adjusting_other_reserve_amt) AS itd_adjusting_other_reserve_amt,
		SUM(subro_reserve_amt) AS subro_reserve_amt,SUM(itd_subro_reserve_amt) AS itd_subro_reserve_amt,
		SUM(salvage_reserve_amt) AS salvage_reserve_amt,SUM(itd_salvage_reserve_amt) AS itd_salvage_reserve_amt,
		SUM(salvage_expense_reserve_amt) AS salvage_expense_reserve_amt,SUM(itd_salvage_expense_reserve_amt) AS itd_salvage_expense_reserve_amt,
		SUM(subro_expense_reserve_amt) AS subro_expense_reserve_amt,SUM(itd_subro_expense_reserve_amt) AS itd_subro_expense_reserve_amt,
		SUM(loss_paid_amt) AS loss_paid_amt,SUM(itd_loss_paid_amt) AS itd_loss_paid_amt,
		SUM(expense_paid_amt) AS expense_paid_amt,SUM(itd_expense_paid_amt) AS itd_expense_paid_amt,
		SUM(adjusting_other_paid_amt) AS adjusting_other_paid_amt,SUM(itd_adjusting_other_paid_amt) AS itd_adjusting_other_paid_amt,
		SUM(subro_recovery_amt) AS subro_recovery_amt,SUM(itd_subro_recovery_amt) AS itd_subro_recovery_amt,
		SUM(salvage_recovery_amt) AS salvage_recovery_amt,SUM(itd_salvage_recovery_amt) AS itd_salvage_recovery_amt,
		SUM(salvage_expense_paid_amt) AS salvage_expense_paid_amt,SUM(itd_salvage_expense_paid_amt) AS itd_salvage_expense_paid_amt,
		SUM(subro_expense_paid_amt) AS subro_expense_paid_amt,SUM(itd_subro_expense_paid_amt) AS itd_subro_expense_paid_amt,
		SUM(refund_indemnity_paid_amt) AS refund_indemnity_paid_amt,SUM(itd_refund_indemnity_paid_amt) AS itd_refund_indemnity_paid_amt,
		SUM(refund_expense_paid_amt) AS refund_expense_paid_amt,SUM(itd_refund_expense_paid_amt) AS itd_refund_expense_paid_amt,
		SUM(dcc_expense_paid_amt) AS dcc_expense_paid_amt,
		MAX(feature_open_ct) AS open_claim_ct, 
		MIN(feature_closed_ct) AS closed_claim_ct,
		SUM(itd_refund_paid_amt) AS itd_refund_paid_amt,
		SUM(itd_total_incurred_amt) AS itd_total_incurred_amt,
		SUM(itd_total_paid_amt) AS itd_total_paid_amt,
		SUM(itd_total_reserve_amt) AS itd_total_reserve_amt,
		SUM(itd_dcc_expense_paid_amt) AS itd_dcc_expense_paid_amt,
		source_system_sk,@current_date AS update_ts,@etl_audit_sk
		FROM
			edw_core.tclaim_feature_summary 
		WHERE month_sk=@end_dt_sk
		GROUP BY month_sk, claim_sk, product_sk, policy_sk, broker_sk, customer_sk,source_system_sk

		SET @parameter_desc='@begin_dt_sk='+ CAST(@begin_dt_sk as varchar(100)) + '@end_dt_sk='+ CAST(@end_dt_sk as varchar(100))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc

		SET @rows_affected=@@ROWCOUNT
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		UPDATE tclaim_summary
		SET
		itd_loss_incurred_gt_250k_ct=(CASE WHEN itd_total_incurred_amt>250000 THEN 1 ELSE 0 END),
		itd_loss_incurred_gt_500k_ct=(CASE WHEN itd_total_incurred_amt>500000 THEN 1 ELSE 0 END),
		claim_closed_with_pay_ct=(CASE WHEN closed_claim_ct=1 AND (itd_total_paid_amt-itd_dcc_expense_paid_amt-itd_subro_expense_paid_amt-itd_salvage_expense_paid_amt-itd_salvage_recovery_amt-itd_subro_recovery_amt)>0 THEN 1 ELSE 0 END),
		claim_closed_without_pay_ct=(CASE WHEN closed_claim_ct=1 AND (itd_total_paid_amt-itd_dcc_expense_paid_amt-itd_subro_expense_paid_amt-itd_salvage_expense_paid_amt-itd_salvage_recovery_amt-itd_subro_recovery_amt)=0 THEN 1 ELSE 0 END),
		itd_dcc_expense_paid_on_close_amt=(CASE WHEN closed_claim_ct=1 THEN itd_dcc_expense_paid_amt ELSE 0 END )
		WHERE month_sk=@end_dt_sk;
		FETCH NEXT FROM cur_main INTO @begin_dt_sk,@end_dt_sk
    END
	
	CLOSE cur_main;

	DEALLOCATE cur_main;

END
