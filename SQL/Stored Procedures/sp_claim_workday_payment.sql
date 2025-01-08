-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts workday payment data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/28/23		Yunus Mohammed				1. Created this procedure 
-- 11/29/23		Yunus Mohammed				2. Update logic to get begin and end date
-- 03/21/24		Yunus Mohammed				3. Added party_subtype_role_nm in output
-- 07/31/24		Yunus Mohammed				4. Updated Loss (Expense A&O) to Loss (Expense - A&O)
-- 09/19/24		Yunus Mohammed				5. Used sub_cause_of_loss_cd AS sub_cause_of_loss_code instead of sub_cause_of_loss_desc
--												added throw in catch block
-- 11/26/24		Yunus Mohammed				6. Updated "Marine Boat & Yacht" to "Marine_Boat&Yacht"
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_workday_payment]
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

		DROP TABLE IF EXISTS edw_temp.claim_workday_payment_feed_temp1

		DECLARE @year_month INT,@begin_dt DATE,@end_dt DATE,@begin_sk INT,@end_sk INT
		
		DECLARE cur_main CURSOR FOR
		SELECT yearmonth
		FROM edw_core.tdate
		WHERE
			actual_dt >= CAST(@last_source_extract_ts AS DATE)
			and actual_dt <= CAST(DATEADD(MONTH,-1,@current_date) AS DATE)
		GROUP BY yearmonth
		ORDER BY yearmonth

		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @year_month
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
			SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
			
			select @begin_dt = MIN(actual_dt),@end_dt = MAX(actual_dt), @begin_sk = MIN(date_sk),
			@end_sk = MAX(date_sk) 
			from
			edw_core.tdate
			where
			yearmonth=@year_month;
			
			DELETE FROM edw_integration.claim_workday_payment_feed WHERE transaction_date BETWEEN @begin_dt AND @end_dt;
		
			WITH claim_workday_payment_feed_temp AS
			(
			SELECT
			CASE
				WHEN tc.underwriting_company_nm='VRE' THEN 'Vault Reciprocal Exchange'
				WHEN tc.underwriting_company_nm='VES' THEN 'Vault E&S Insurance Company'
				ELSE tc.underwriting_company_nm
			END AS company,
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
			CASE WHEN tc.policy_no LIKE 'NFP%' THEN 'Group Umbrella'
				WHEN tprd.product_nm = 'Auto' THEN 'Automobile'
				WHEN tprd.product_nm = 'Excess Liability' THEN 'Excess_Liability'
				WHEN tprd.product_nm = 'Condo' THEN 'Homeowners'
				WHEN tprd.product_cd = 'Marine Boat & Yacht' THEN 'Marine_Boat&Yacht'
			ELSE tprd.product_nm END AS product,
			tcf.claim_coverage_desc AS policycoveragetype,
			ttr.cat_name AS paymenttype,
			tpay.payee_nm AS payeename,
			ttr.amt AS paymentamount,
			tpay.party_role_nm AS settlementtype,
			YEAR(tc.loss_dt) AS accident_year,
			CASE WHEN tc.policy_no LIKE 'NFP%' THEN np.risk_state ELSE COALESCE(st.state_cd,tp.risk_state_cd) END AS risk_state,
			CAST(tasl.aslob_cd AS INT) AS aslob,
			tpay.payment_sequence_no AS transaction_id,
			@end_dt AS monthend,
			tscl.sub_cause_of_loss_cd AS sub_cause_of_loss_code,
			tscl.sub_cause_of_loss_desc AS sub_cause_of_loss_name,
			tc.claim_status AS claim_status,
			tcf.claim_feature_status AS loss_status,
			tpay.party_subtype_role_nm
			FROM
			edw_core.tclaim tc
			LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_sk=tc.cause_of_loss_sk
			LEFT JOIN edw_core.tcatastrophe tcat ON tcat.catastrophe_sk=tc.catastrophe_sk
			LEFT JOIN edw_core.tsub_cause_of_loss tscl ON tscl.sub_cause_of_loss_sk=tc.sub_cause_of_loss_sk
			INNER JOIN edw_core.tclaim_feature tcf ON tc.claim_sk=tcf.claim_sk
			LEFT JOIN edw_core.taslob tasl ON tasl.aslob_sk=tcf.aslob_sk
			INNER JOIN edw_core.tproduct tprd ON tprd.product_sk=tc.product_sk
			INNER JOIN edw_core.tclaim_payment tpay ON tpay.claim_feature_sk=tcf.claim_feature_sk
			INNER JOIN edw_core.tclaim_transaction tcr ON tcr.claim_feature_sk = tcr.claim_feature_sk AND tcr.claim_payment_sk=tpay.claim_payment_sk
			LEFT JOIN
							(
								SELECT
									ROW_NUMBER()OVER(partition by policy_no, insured_cert_no order by transaction_date desc) as transaction_seq_no,
									insured_cert_no as policy_no,CONCAT_WS(' ',insured_first_name,insured_last_name) as insured_nm,
									risk_state,product_type
								FROM
									edw_stage.nfp_policy

							) AS np ON tc.policy_no = np.policy_no and np.transaction_seq_no=1
			INNER JOIN
			(
				SELECT
					claim_feature_sk,claim_payment_sk,cat_name,SUM(amt) AS amt
				FROM
					(
						SELECT
							claim_feature_sk,claim_payment_sk,SUM(loss_paid_amt+refund_indemnity_paid_amt) AS amt, 'Loss (Indemnity)' AS cat_name
						FROM edw_core.tclaim_transaction t
						WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
						GROUP BY claim_feature_sk,claim_payment_sk

						UNION
							
						SELECT
							claim_feature_sk,claim_payment_sk,SUM(expense_paid_amt+adjusting_other_paid_amt+refund_expense_paid_amt) AS amt, 'Loss (Expense - A&O)' AS cat_name
						FROM edw_core.tclaim_transaction t
						WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
						AND t.defense_cost_in = 'N'
						GROUP BY claim_feature_sk,claim_payment_sk

						UNION
							
						SELECT
							claim_feature_sk,claim_payment_sk,SUM(expense_paid_amt+adjusting_other_paid_amt+refund_expense_paid_amt) AS amt, 'Loss (Expense - DCC)' AS cat_name
						FROM edw_core.tclaim_transaction t
						WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
						AND t.defense_cost_in = 'Y'
						GROUP BY claim_feature_sk,claim_payment_sk
							
						UNION
							
						SELECT
							claim_feature_sk,claim_payment_sk,SUM(subro_recovery_amt+subro_expense_paid_amt) AS amt, 'Subrogation' AS cat_name
						FROM edw_core.tclaim_transaction t
						WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
						GROUP BY claim_feature_sk,claim_payment_sk

						UNION

						SELECT
							claim_feature_sk,claim_payment_sk,SUM(salvage_recovery_amt + salvage_expense_paid_amt) AS amt, 'Salvage' AS cat_name
						FROM edw_core.tclaim_transaction t
						WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
						GROUP BY claim_feature_sk,claim_payment_sk
					) AS A
					GROUP BY claim_feature_sk,claim_payment_sk,cat_name
			) AS ttr ON ttr.claim_feature_sk=tcr.claim_feature_sk and ttr.claim_payment_sk=tcr.claim_payment_sk
			LEFT JOIN edw_core.tpolicy tp on tp.policy_no=tc.policy_no
			LEFT JOIN edw_core.tstate st on st.state_cd=tp.risk_state_cd
			WHERE tcr.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
			AND ttr.amt!=0
			)

			INSERT INTO edw_integration.claim_workday_payment_feed
			(
			company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
			zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,paymenttype,payeename,paymentamount,settlementtype,
			accident_year,risk_state,aslob,transaction_id,monthend,sub_cause_of_loss_code,sub_cause_of_loss_name,claim_status,loss_status,party_subtype_role_nm,
			create_ts,update_ts,etl_audit_sk
			)
			SELECT
				company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
				zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,paymenttype,payeename,paymentamount,settlementtype,
				accident_year,risk_state,aslob,transaction_id,monthend,sub_cause_of_loss_code,sub_cause_of_loss_name,claim_status,loss_status,party_subtype_role_nm,
				GETDATE() AS create_ts,GETDATE() AS update_ts, @etl_audit_sk AS etl_audit_sk
			FROM
				claim_workday_payment_feed_temp

			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

			SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

			FETCH NEXT FROM cur_main INTO @year_month
		END
		CLOSE cur_main;

		DEALLOCATE cur_main;
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
