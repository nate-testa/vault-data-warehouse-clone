-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates claim transaction data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 08/03/23		Yunus Mohammed				1. Created this procedure
-- 11/20/23		Yunus Mohammed				2. Added Throw
-- 12/08/23		Yunus Mohammed				3. Added policy_sk, broker_sk and customer_sk
-- 12/19/23		Yunus Mohammed				4. Update calculation logic for expense_reserve_amt and refund_expense_paid_amt
-- 12/27/23		Yunus Mohammed				5. Reverted calculation logic for expense_reserve_amt and refund_expense_paid_amt
-- 03/01/24		Yunus Mohammed				6. Update calculation logic for refund_expense_paid_amt
-- 07/16/24		Yunus Mohammed				6. Update calculation logic for refund_expense_paid_amt
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_transaction]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON
		BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.tclaim_transaction_temp1

		SELECT
		tc.claim_sk,tcf.claim_feature_sk,tc.policy_sk,tbrk.broker_sk,tcust.customer_sk,
		 -- Transact.settlement_id, 
		Transact.dcc_in AS defense_cost_in,td.date_sk,Transact.post_date AS transaction_ts,
		tc.product_sk,tcp.claim_payment_sk,
		Transact.claim_transaction_type_sk,ts.claim_status_sk AS feature_status_sk,
		ISNULL(Transact.loss_reserve_amt,0) AS loss_reserve_amt, 
		ISNULL(Transact.expense_reserve_amt,0) AS expense_reserve_amt, 
		ISNULL(Transact.adjusting_other_reserve_amt,0) AS adjusting_other_reserve_amt, 
		ISNULL(Transact.subro_reserve_amt,0) AS subro_reserve_amt, 
		ISNULL(Transact.salvage_reserve_amt,0)  AS salvage_reserve_amt, 
		ISNULL(Transact.salvage_expense_reserve_amt,0) AS salvage_expense_reserve_amt,
		ISNULL(Transact.subro_expense_reserve_amt,0) AS subro_expense_reserve_amt,
		ISNULL(Transact.loss_paid_amt,0) AS loss_paid_amt, 
		ISNULL(Transact.expense_paid_amt,0) AS expense_paid_amt, 
		ISNULL(Transact.adjusting_other_paid_amt,0) AS adjusting_other_paid_amt,
		ISNULL(Transact.subro_recovery_amt,0) AS subro_recovery_amt,
		ISNULL(Transact.salvage_recovery_amt,0) AS salvage_recovery_amt, 
		ISNULL(Transact.salvage_expense_paid_amt,0) AS salvage_expense_paid_amt, 
		ISNULL(Transact.subro_expense_paid_amt,0) AS subro_expense_paid_amt,
		ISNULL(Transact.refund_indemnity_paid_amt,0) AS refund_indemnity_paid_amt,
		ISNULL(Transact.refund_expense_paid_amt,0) AS refund_expense_paid_amt,
		3 AS source_system_sk,@current_date AS create_ts,@current_date AS update_ts
	INTO edw_temp.tclaim_transaction_temp1
	FROM
		edw_stage.t_clm_case tcase
		INNER JOIN edw_stage.t_clm_object AS obj ON tcase.case_id=obj.case_id
		INNER JOIN edw_stage.t_clm_item AS e ON obj.[object_id] = e.[object_id]
		INNER JOIN edw_core.tclaim tc ON tc.claim_no=tcase.claim_no
		INNER JOIN edw_core.tclaim_feature tcf ON tcf.claim_no=tc.claim_no
			AND tcf.subclaim_seq_no=obj.seq_no AND tcf.claim_coverage_cd=e.coverage_code
		LEFT JOIN edw_core.tbroker tbrk ON tbrk.broker_id = tc.broker_id	
		LEFT JOIN edw_core.tcustomer tcust ON tcust.customer_id = [tc].customer_id
		INNER JOIN
		(
			SELECT
			t1.item_id, claim_transaction_type_sk,
			t1.post_date, 
			cast(t1.post_date as date) AS transaction_dt,
			t1.business_instance_id AS settlement_id,t1.NEW_STATUS,
			SUM(CASE WHEN t1.reserve_type='RC_01' THEN outstanding_changed ELSE 0 END) AS loss_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_02' THEN outstanding_changed ELSE 0 END) AS expense_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_03' THEN outstanding_changed ELSE 0 END) AS adjusting_other_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_04' THEN outstanding_changed ELSE 0 END) AS subro_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_05' THEN outstanding_changed ELSE 0 END) AS salvage_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_06' THEN outstanding_changed ELSE 0 END) AS salvage_expense_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_07' THEN outstanding_changed ELSE 0 END) AS subro_expense_reserve_amt,
			SUM(CASE WHEN t1.reserve_type='RC_01' AND t1.claim_type='LOS' AND settle_changed > 0 THEN settle_changed ELSE 0 END) AS loss_paid_amt,
			SUM(CASE WHEN t1.reserve_type='RC_02' AND t1.claim_type='LOS' AND settle_changed > 0 THEN settle_changed ELSE 0 END) AS expense_paid_amt,
			SUM(CASE WHEN t1.reserve_type='RC_03' THEN settle_changed ELSE 0 END) AS adjusting_other_paid_amt,
			SUM(CASE WHEN t1.reserve_type='RC_04' THEN settle_changed ELSE 0 END) AS subro_recovery_amt,
			SUM(CASE WHEN t1.reserve_type='RC_05' OR (t1.reserve_type='RC_01' AND t1.claim_type LIKE '%SAL%' AND 
			CAST(t1.payee_name AS VARCHAR(MAX))='Copart') THEN settle_changed ELSE 0 END) AS salvage_recovery_amt,
			SUM(CASE WHEN t1.reserve_type='RC_06' THEN settle_changed ELSE 0 END) AS salvage_expense_paid_amt,
			SUM(CASE WHEN t1.reserve_type='RC_07' THEN settle_changed ELSE 0 END) AS subro_expense_paid_amt,			
			SUM(CASE WHEN t1.reserve_type='RC_01' AND t1.claim_type='LOS' AND settle_changed < 0 THEN settle_changed
					WHEN t1.reserve_type ='RC_01' AND t1.claim_type LIKE '%SAL%' AND CAST(t1.payee_name AS VARCHAR(MAX)) NOT IN ('Copart') THEN settle_changed
					ELSE 0 END
				) AS refund_indemnity_paid_amt,
			SUM(CASE WHEN t1.reserve_type='RC_02' AND 
			(
				(t1.claim_type = 'LOS' AND settle_changed < 0)
				OR
				(t1.claim_type ='LOS,SAL,SUB'  AND settle_changed != 0 )
			)
			THEN settle_changed ELSE 0 END) AS refund_expense_paid_amt,
			MAX(CASE WHEN t1.ROLE_NAME = 'Lawyer' OR t1.ROLE_NAME  = 'Legal Firm' THEN 'Y' ELSE 'N' END) AS dcc_in
			FROM
			(
				SELECT a.*, settle.claim_type, settle_payee.payee_name, party.party_role ,
				tt.claim_transaction_type_sk,party_role.ROLE_NAME
				FROM
				edw_stage.t_clm_reserve_his AS a
				LEFT JOIN edw_stage.t_clm_settle_item AS settle_item ON a.item_id = settle_item.item_id
					AND a.business_instance_id = settle_item.settle_item_id
				LEFT JOIN edw_stage.t_clm_settle_payee AS settle_payee ON settle_payee.settle_payee_id  = settle_item.settle_payee_id
				LEFT JOIN edw_stage.t_clm_settle AS settle ON settle.settle_id = settle_payee.settle_id
				LEFT JOIN edw_stage.t_clm_party AS party ON settle.case_id = party.case_id AND party.party_id = settle_payee.payee_id
				LEFT JOIN edw_stage.t_clm_party_role AS party_role ON party.PARTY_ROLE = party_role.ROLE_CODE
				LEFT JOIN edw_core.tclaim_transaction_type tt ON tt.claim_transaction_type_cd=a.reserve_type
			) t1
		
			GROUP BY item_id, claim_transaction_type_sk, t1.post_date,t1.business_instance_id,NEW_STATUS 
			-- ORDER BY item_id, post_date ASC
		) Transact ON e.item_id = Transact.item_id
		LEFT JOIN edw_core.tdate td ON td.actual_dt=Transact.transaction_dt
		LEFT JOIN edw_core.tclaim_status ts ON 
		CASE WHEN UPPER(ts.claim_status)='CLOSE' THEN 'CLOSED'
		ELSE UPPER(ts.claim_status) END=UPPER(Transact.NEW_STATUS)
		LEFT JOIN edw_core.tclaim_payment tcp ON tcp.payment_sequence_no=Transact.settlement_id
		AND tcf.claim_feature_sk=tcp.claim_feature_sk
		AND (
			Transact.loss_paid_amt + Transact.expense_paid_amt + Transact.adjusting_other_paid_amt + 
			Transact.subro_recovery_amt + Transact.salvage_recovery_amt + Transact.salvage_expense_paid_amt + 
			Transact.subro_expense_paid_amt 
			 + Transact.refund_indemnity_paid_amt + Transact.refund_expense_paid_amt 
			)!=0.00
		WHERE 
			Transact.post_date > @last_source_extract_ts;
		
		INSERT INTO edw_core.tclaim_transaction
		(
			claim_sk,claim_feature_sk,product_sk,policy_sk,broker_sk,customer_sk,defense_cost_in,transaction_dt_sk,transaction_ts,claim_payment_sk,
			claim_transaction_type_sk,feature_status_sk,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,subro_reserve_amt,
			salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,adjusting_other_paid_amt,
			subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,refund_indemnity_paid_amt,refund_expense_paid_amt,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			claim_sk,claim_feature_sk,product_sk,policy_sk,broker_sk,customer_sk,defense_cost_in,date_sk,transaction_ts,claim_payment_sk,
		claim_transaction_type_sk,feature_status_sk,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt, 
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt, 
		expense_paid_amt,adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
		refund_indemnity_paid_amt,refund_expense_paid_amt,source_system_sk,create_ts,update_ts,@etl_audit_sk
		FROM
			edw_temp.tclaim_transaction_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_ts) FROM edw_temp.tclaim_transaction_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

