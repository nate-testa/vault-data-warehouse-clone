SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Description: This procedures inserts and updates claim notes snapsheet
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/30/24		Hernando Gonzalez			1. Created this procedure - AD7391
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_transaction_snapsheet]
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

		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp1;

	SELECT 
		tc.claim_sk,
		NULL AS claim_feature_sk,
		tpr.product_sk,
		tc.policy_sk,
		tb.broker_sk,
		tcu.customer_sk,
		NULL AS defense_cost_in,
		td1.date_sk AS transaction_dt_sk,
		ft.created_at AS transaction_ts,
		CONCAT(fpi.financial_transaction_id,'-',fpi.exposure_id) AS claim_payment_sk,
		NULL AS claim_transaction_type_sk,
		e.status AS feature_status_sk,
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method IS NULL 			THEN fri.amount ELSE 0 END) as loss_reserve_amt, 
		NULL AS expense_reserve_amt,
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method IS NULL 			THEN fri.amount ELSE 0 END) as adjusting_other_reserve_amt, 
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method = 'subrogation' 	THEN fri.amount ELSE 0 END) as subro_reserve_amt, 
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method = 'salvage' 		THEN fri.amount ELSE 0 END) as salvage_reserve_amt,
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method = 'salvage' 		THEN fri.amount ELSE 0 END) as salvage_expense_reserve_amt,
		(CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method = 'subrogation' 	THEN fri.amount ELSE 0 END) as subro_expense_reserve_amt,
		-- (CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method IS NULL 			THEN fri.amount ELSE 0 END) as defense_reserve_amt, 
		-- (CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method = 'subrogation' 	THEN fri.amount ELSE 0 END) as subro_defense_reserve_amt,
		-- (CASE WHEN SUBSTRING(fri.cost_type, CHARINDEX('_', fri.cost_type) + 1, LEN(fri.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method = 'salvage' 		THEN fri.amount ELSE 0 END) as salvage_defense_reserve_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method IS NULL 			THEN pay.amount ELSE 0 END) as loss_paid_amt, 
		NULL AS expense_paid_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method IS NULL 			THEN pay.amount ELSE 0 END) as adjusting_other_paid_amt, 
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method = 'subrogation' 	THEN pay.amount ELSE 0 END) as subro_recovery_amt, 
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method = 'salvage' 		THEN pay.amount ELSE 0 END) as salvage_recovery_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method = 'salvage' 		THEN pay.amount ELSE 0 END) as salvage_expense_paid_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method = 'subrogation' 	THEN pay.amount ELSE 0 END) as subro_expense_paid_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_claim%' 		AND fri.reserve_method = 'overpayment' 	THEN pay.amount ELSE 0 END) as refund_indemnity_paid_amt,
		(CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_adjusting%' 	AND fri.reserve_method = 'overpayment' 	THEN pay.amount ELSE 0 END) as refund_expense_paid_amt,
		-- (CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method IS NULL 			THEN pay.amount ELSE 0 END) as defense_recovery_amt, 
		-- (CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method = 'subrogation' 	THEN pay.amount ELSE 0 END) as subro_defense_paid_amt,
		-- (CASE WHEN SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) LIKE '%_defense%' 	AND fri.reserve_method = 'salvage' 		THEN pay.amount ELSE 0 END) as salvage_defense_paid_amt,
		5 AS source_system_sk
	INTO edw_temp.tclaim_transaction_snapsheet_temp1
	FROM edw_stage_snapsheet.financial_transactions as ft
	INNER JOIN edw_stage_snapsheet.claims as c ON c.id = ft.claim_id
	INNER JOIN edw_core.tclaim as tc ON tc.claim_no = c.claim_number
	LEFT JOIN edw_stage_snapsheet.financial_payment_items as fpi ON fpi.financial_transaction_id = ft.id
	LEFT JOIN edw_stage_snapsheet.financial_reserve_items as fri ON fri.financial_transaction_id = ft.id
	LEFT JOIN edw_stage_snapsheet.exposures as e ON e.id = fri.exposure_id AND e.claim_id = c.id
	LEFT JOIN edw_stage_snapsheet.financial_payment_items as pay
		ON pay.financial_transaction_id = ft.id
		AND pay.exposure_id = fri.exposure_id
		AND pay.cost_category = fri.cost_category
	LEFT JOIN edw_core.tpolicy as tp ON tp.policy_sk = tc.policy_sk
	LEFT JOIN edw_core.tbroker as tb ON tb.broker_id = tp.broker_id
	LEFT JOIN edw_core.tcustomer as tcu ON tcu.customer_id = tp.customer_id
	LEFT JOIN edw_core.tdate as td1 ON td1.actual_dt = CAST(ft.created_at AS DATE)
	LEFT JOIN edw_core.tproduct as tpr ON tpr.product_cd = (CASE 
																WHEN c.claim_type = 'auto' THEN 'AU' 
																WHEN c.claim_type = 'liability' THEN 'PEL' 
																WHEN c.claim_type = 'property' THEN 'HO' 
																ELSE c.claim_type 
															END)
	;

	-- Start Insert process
		INSERT INTO edw_core.tclaim_transaction_snapsheet
		(
			claim_sk,
			claim_feature_sk,
			product_sk,
			policy_sk,
			broker_sk,
			customer_sk,
			defense_cost_in,
			transaction_dt_sk,
			transaction_ts,
			claim_payment_sk,
			claim_transaction_type_sk,
			feature_status_sk,
			loss_reserve_amt,
			expense_reserve_amt ,
			adjusting_other_reserve_amt,
			subro_reserve_amt,
			salvage_reserve_amt,
			salvage_expense_reserve_amt,
			subro_expense_reserve_amt,
			loss_paid_amt,
			expense_paid_amt,
			adjusting_other_paid_amt,
			subro_recovery_amt,
			salvage_recovery_amt,
			salvage_expense_paid_amt,
			subro_expense_paid_amt,
			refund_indemnity_paid_amt,
			refund_expense_paid_amt,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT 
			claim_sk,
			claim_feature_sk,
			product_sk,
			policy_sk,
			broker_sk,
			customer_sk,
			defense_cost_in,
			transaction_dt_sk,
			transaction_ts,
			claim_payment_sk,
			claim_transaction_type_sk,
			feature_status_sk,
			loss_reserve_amt,
			expense_reserve_amt ,
			adjusting_other_reserve_amt,
			subro_reserve_amt,
			salvage_reserve_amt,
			salvage_expense_reserve_amt,
			subro_expense_reserve_amt,
			loss_paid_amt,
			expense_paid_amt,
			adjusting_other_paid_amt,
			subro_recovery_amt,
			salvage_recovery_amt,
			salvage_expense_paid_amt,
			subro_expense_paid_amt,
			refund_indemnity_paid_amt,
			refund_expense_paid_amt,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk,
			GETDATE() AS create_ts,
			GETDATE() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tclaim_transaction_snapsheet_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(note_created_ts) FROM edw_temp.tclaim_transaction_snapsheet_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp1

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
