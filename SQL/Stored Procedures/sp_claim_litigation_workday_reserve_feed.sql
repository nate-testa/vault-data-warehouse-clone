-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 04/23/2025
-- Description: This procedures inserts workday litigation claims reserve data
---------------------------------------------------------------------------------------------------
-- Change date                  |Author						            |	Change Description
---------------------------------------------------------------------------------------------------
-- 07/28/23		                Yunus Mohammed				1. Created this procedure
-- =================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_workday_reserve_feed_itd]
AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
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
		
		DROP TABLE IF EXISTS edw_temp.claim_workday_reserve_feed_itd_temp1

		DECLARE @last_day_month DATE, @year_month INT;

		SELECT @year_month = yearmonth FROM edw_core.tdate WHERE actual_dt = CAST(DATEADD(MONTH,-1,GETDATE()) AS DATE);

		SELECT @last_day_month = actual_dt FROM edw_core.tdate WHERE yearmonth = @year_month and month_end_in = 'Y';

		WITH claim_reserve_itd_feed_temp AS
		(
		SELECT
			DISTINCT
			tc.underwriting_company_nm AS company,
			tc.claim_no AS claim_no,
			tc.policy_no AS policy_no,
			CAST(tcr.transaction_ts AS DATE) AS transaction_date,
			tc.policy_effective_dt AS policyeffectivedate,
			tc.loss_dt AS claimlossdate,
			tc.report_dt AS claimreporteddate,
			tc.loss_address AS [address],
			tc.loss_city_nm AS city,
			tc.loss_state_cd AS [state],
			tc.loss_zip_cd AS zip,
			tcl.cause_of_loss_desc AS causeofloss,
			tcat.catastrophe_cd AS catastrophecode,
			tcat.catastrophe_nm AS catastrophename,			
			CASE
				WHEN tprd.product_nm = 'Auto' THEN 'Automobile'
				WHEN tprd.product_nm = 'Excess Liability' THEN 'Excess_Liability'
				WHEN tprd.product_nm = 'Condo' THEN 'Homeowners'
				WHEN tprd.product_cd = 'Marine Boat & Yacht' THEN 'Marine_Boat&Yacht'
			ELSE tprd.product_nm END AS product,
			tcf.claim_coverage_desc AS policycoveragetype,
			CASE
				WHEN					
						(tcr.loss_reserve_amt + tcr.deductible_recovery_reserve_amt+ tcr.overpayment_recovery_reserve_amt) != 0
					THEN 'Loss (Indemnity)'
					
					WHEN (tcr.deductible_recovery_expense_reserve_amt + tcr.expense_reserve_amt + tcr.overpayment_recovery_expense_reserve_amt) !=0
					THEN 'Loss (Expense - A&O)'

					WHEN (tcr.deductible_recovery_defense_reserve_amt + tcr.defense_reserve_amt + tcr.overpayment_recovery_defense_reserve_amt) !=0
					THEN 'Loss (Expense - DCC)'

					WHEN (tcr.salvage_recovery_reserve_amt + tcr.salvage_recovery_defense_reserve_amt) !=0 THEN 'Salvage'

					WHEN tcr.salvage_recovery_expense_reserve_amt !=0 THEN 'Salvage Expenses'

					WHEN (tcr.subrogation_recovery_reserve_amt + tcr.subrogation_recovery_defense_reserve_amt) != 0 THEN 'Subrogation'

					WHEN tcr.subrogation_recovery_expense_reserve_amt !=0 THEN 'Subrogation Expense'
			END AS reserve_type,
			(
					tcr.deductible_recovery_expense_reserve_amt + tcr.expense_reserve_amt +
					tcr.overpayment_recovery_expense_reserve_amt + tcr.deductible_recovery_defense_reserve_amt +
					tcr.defense_reserve_amt + tcr.overpayment_recovery_defense_reserve_amt +
					tcr.loss_reserve_amt + tcr.deductible_recovery_reserve_amt + tcr.overpayment_recovery_reserve_amt +
					tcr.salvage_recovery_reserve_amt + tcr.salvage_recovery_defense_reserve_amt + tcr.salvage_recovery_expense_reserve_amt +
					tcr.subrogation_recovery_expense_reserve_amt + tcr.subrogation_recovery_reserve_amt +tcr.subrogation_recovery_defense_reserve_amt
			) AS reserve_amount,
			YEAR(tc.loss_dt) AS accident_year,
			COALESCE(st.state_cd,tp.risk_state_cd) AS risk_state,			
			CAST(tasl.aslob_cd AS INT) AS aslob,
			tcr.claim_transaction_sk AS transaction_id,
			@last_day_month AS monthend,
			tp.insured_nm AS insured_nm,			
			tc.claim_status AS claim_status,
			tcf.claim_feature_status AS loss_status
			FROM
				edw_core.tclaim tc
				LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_sk=tc.cause_of_loss_sk
				LEFT JOIN edw_core.tcatastrophe tcat ON tcat.catastrophe_sk=tc.catastrophe_sk
				INNER JOIN edw_core.tclaim_feature tcf ON tc.claim_sk=tcf.claim_sk
				LEFT JOIN edw_core.taslob tasl ON tasl.aslob_sk=tcf.aslob_sk
				INNER JOIN edw_core.tproduct tprd ON tprd.product_sk=tc.product_sk
				INNER JOIN edw_core.tclaim_transaction tcr ON tcr.claim_feature_sk=tcf.claim_feature_sk
				LEFT JOIN edw_core.tclaim_payment tpay ON tpay.claim_feature_sk=tcf.claim_feature_sk  AND tcr.claim_payment_sk=tpay.claim_payment_sk
				LEFT JOIN edw_core.tpolicy tp ON tp.policy_no=tc.policy_no
				LEFT JOIN edw_core.tstate st ON st.state_cd=tp.risk_state_cd
				LEFT JOIN edw_core.tdate td ON td.date_sk = tcr.transaction_dt_sk
				LEFT JOIN edw_core.tdate tdld ON tdld.yearmonth = td.yearmonth and tdld.month_end_in='Y'
				WHERE
						tc.policy_no like '%VRE' or tc.policy_no like '%VES'
		)

		INSERT INTO edw_integration.claim_workday_itd_reserve_feed
		(
		company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
		zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,reserve_type,reserve_amount,accident_year,
		risk_state,aslob,transaction_id,monthend,insuredname,claim_status,
		loss_status,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
			zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,reserve_type,reserve_amount,accident_year,
			risk_state,aslob,transaction_id,monthend,insured_nm,claim_status,
			loss_status,GETDATE() AS create_ts,GETDATE() AS update_ts, @etl_audit_sk AS etl_audit_sk
		FROM
			claim_reserve_itd_feed_temp
		WHERE
			reserve_amount != 0
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_time) FROM edw_temp.claim_workday_reserve_feed),@last_source_extract_ts)
		SET @new_last_source_extract_ts = '1900-01-01 00:00:00.0000000'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.claim_workday_reserve_feed_itd_temp1
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