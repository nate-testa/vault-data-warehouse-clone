-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedure calculate claim amounts at claim level
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 09/28/2023		Yunus Mohammed					1. Procedure created
-- 10/04/2023		Yunus Mohammed					2. Removed start date & end date param
-- 12/22/2023		Yunus Mohammed					3. Added try catch block and update end_dt_sk logic for current month
-- 05/21/2024		Yunus Mohammed					5. Updates were made to calculate start month and end month
-- 05/23/2024		Yunus Mohammed					6. Updates were made to select the previous month and obtain the last day's transaction from that month on the 1st of the current month
-- 02/06/2025		Yunus Mohammed					7. Procedure update for Snapsheet
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_summary]
AS
BEGIN
DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
	
	BEGIN TRY
		DECLARE @etl_audit_sk INT
		DECLARE @begin_dt_sk INT
		DECLARE @end_dt_sk INT
		DECLARE @begin_dt DATE
		DECLARE @end_dt DATE
		DECLARE @yearmonth INT
		DECLARE @rows_affected INT
		DECLARE @procedure_sk INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @new_last_source_extract_ts DATETIME2(7)

			-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

		DECLARE cur_main CURSOR FOR	
		SELECT td.yearmonth, MIN(td.date_sk) AS begin_dt_sk, MAX(td.date_sk) AS end_dt_sk, MIN(td.actual_dt) AS begin_dt, MAX(td.actual_dt) AS end_dt		
		FROM edw_core.tdate as td
		where yearmonth in ( SELECT distinct yearmonth 
								FROM edw_core.tdate
								WHERE actual_dt >= @last_source_extract_ts and actual_dt <= EOMONTH(@current_date)
							) 
		GROUP BY yearmonth
		ORDER BY yearmonth;
		
		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @yearmonth, @begin_dt_sk ,@end_dt_sk , @begin_dt, @end_dt;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
			SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
			DELETE FROM edw_core.tclaim_summary WHERE month_sk=@end_dt_sk

			INSERT INTO edw_core.tclaim_summary
			(
				month_sk,claim_sk,product_sk,policy_sk,broker_sk,customer_sk,
				loss_reserve_amt,itd_loss_reserve_amt,expense_reserve_amt,itd_expense_reserve_amt,subrogation_recovery_reserve_amt,
                itd_subrogation_recovery_reserve_amt,salvage_recovery_reserve_amt,itd_salvage_recovery_reserve_amt,salvage_recovery_expense_reserve_amt,
                itd_salvage_recovery_expense_reserve_amt,subrogation_recovery_expense_reserve_amt,itd_subrogation_recovery_expense_reserve_amt,
                loss_paid_amt,itd_loss_paid_amt,expense_paid_amt,itd_expense_paid_amt,subrogation_recovery_amt,itd_subrogation_recovery_amt,
                salvage_recovery_amt,itd_salvage_recovery_amt,salvage_expense_recovery_amt,itd_salvage_expense_recovery_amt,
                subrogation_expense_recovery_amt,itd_subrogation_expense_recovery_amt,open_claim_ct,closed_claim_ct,
                itd_total_incurred_amt,itd_total_paid_amt,itd_total_reserve_amt,defense_reserve_amt,itd_defense_reserve_amt,
                deductible_recovery_reserve_amt,itd_deductible_recovery_reserve_amt,reinsurance_recovery_reserve_amt,
                itd_reinsurance_recovery_reserve_amt,overpayment_recovery_reserve_amt,itd_overpayment_recovery_reserve_amt,
                deductible_recovery_expense_reserve_amt,itd_deductible_recovery_expense_reserve_amt,reinsurance_recovery_expense_reserve_amt,
                itd_reinsurance_recovery_expense_reserve_amt,overpayment_recovery_expense_reserve_amt,itd_overpayment_recovery_expense_reserve_amt,
                subrogation_recovery_defense_reserve_amt,itd_subrogation_recovery_defense_reserve_amt,salvage_recovery_defense_reserve_amt,
                itd_salvage_recovery_defense_reserve_amt,deductible_recovery_defense_reserve_amt,itd_deductible_recovery_defense_reserve_amt,
                reinsurance_recovery_defense_reserve_amt,itd_reinsurance_recovery_defense_reserve_amt,overpayment_recovery_defense_reserve_amt,
                itd_overpayment_recovery_defense_reserve_amt,defense_paid_amt,itd_defense_paid_amt,deductible_recovery_amt,
                itd_deductible_recovery_amt,reinsurance_recovery_amt,itd_reinsurance_recovery_amt,overpayment_recovery_amt,
                itd_overpayment_recovery_amt,deductible_expense_recovery_amt,itd_deductible_expense_recovery_amt,reinsurance_expense_recovery_amt,
                itd_reinsurance_expense_recovery_amt,overpayment_expense_recovery_amt,itd_overpayment_expense_recovery_amt,
                subrogation_defense_recovery_amt,itd_subrogation_defense_recovery_amt,salvage_defense_recovery_amt,itd_salvage_defense_recovery_amt,
                deductible_defense_recovery_amt,itd_deductible_defense_recovery_amt,reinsurance_defense_recovery_amt,
                itd_reinsurance_defense_recovery_amt,overpayment_defense_recovery_amt,itd_overpayment_defense_recovery_amt,
				source_system_sk,update_ts,etl_audit_sk
			)
			SELECT
			@end_dt_sk AS month_sk, claim_sk,product_sk,policy_sk,broker_sk,customer_sk,
            SUM(loss_reserve_amt) AS loss_reserve_amt,
            SUM(itd_loss_reserve_amt) AS itd_loss_reserve_amt,SUM(expense_reserve_amt) AS expense_reserve_amt,
            SUM(itd_expense_reserve_amt) AS itd_expense_reserve_amt,
            SUM(subrogation_recovery_reserve_amt) AS subrogation_recovery_reserve_amt,
                SUM(itd_subrogation_recovery_reserve_amt) AS itd_subrogation_recovery_reserve_amt,
                SUM(salvage_recovery_reserve_amt) AS salvage_recovery_reserve_amt,
                SUM(itd_salvage_recovery_reserve_amt) AS itd_salvage_recovery_reserve_amt,
                SUM(salvage_recovery_expense_reserve_amt) AS salvage_recovery_expense_reserve_amt,
                SUM(itd_salvage_recovery_expense_reserve_amt) AS itd_salvage_recovery_expense_reserve_amt,
                SUM(subrogation_recovery_expense_reserve_amt) AS subrogation_recovery_expense_reserve_amt,
                SUM(itd_subrogation_recovery_expense_reserve_amt) AS itd_subrogation_recovery_expense_reserve_amt,
                SUM(loss_paid_amt) AS loss_paid_amt,
                SUM(itd_loss_paid_amt) AS itd_loss_paid_amt,
                SUM(expense_paid_amt) AS expense_paid_amt,
                SUM(itd_expense_paid_amt) AS itd_expense_paid_amt,
                SUM(subrogation_recovery_amt) AS subrogation_recovery_amt,
                SUM(itd_subrogation_recovery_amt) AS itd_subrogation_recovery_amt,
                SUM(salvage_recovery_amt) AS salvage_recovery_amt,
                SUM(itd_salvage_recovery_amt) AS itd_salvage_recovery_amt,
                SUM(salvage_expense_recovery_amt) AS salvage_expense_recovery_amt,
                SUM(itd_salvage_expense_recovery_amt) AS itd_salvage_expense_recovery_amt,
                SUM(subrogation_expense_recovery_amt) AS subrogation_expense_recovery_amt,
                SUM(itd_subrogation_expense_recovery_amt) AS itd_subrogation_expense_recovery_amt,		
			MAX(feature_open_ct) AS open_claim_ct, 
			MIN(feature_closed_ct) AS closed_claim_ct,
            SUM(itd_total_incurred_amt) AS itd_total_incurred_amt,
            SUM(itd_total_paid_amt) AS itd_total_paid_amt,
            SUM(itd_total_reserve_amt) AS itd_total_reserve_amt,
            SUM(defense_reserve_amt) AS defense_reserve_amt,
            SUM(itd_defense_reserve_amt) AS itd_defense_reserve_amt,
                SUM(deductible_recovery_reserve_amt) AS deductible_recovery_reserve_amt,
                SUM(itd_deductible_recovery_reserve_amt) AS itd_deductible_recovery_reserve_amt,
                SUM(reinsurance_recovery_reserve_amt) AS reinsurance_recovery_reserve_amt,
                SUM(itd_reinsurance_recovery_reserve_amt) AS itd_reinsurance_recovery_reserve_amt,
                SUM(overpayment_recovery_reserve_amt) AS overpayment_recovery_reserve_amt,
                SUM(itd_overpayment_recovery_reserve_amt) AS itd_overpayment_recovery_reserve_amt,
                SUM(deductible_recovery_expense_reserve_amt) AS deductible_recovery_expense_reserve_amt,
                SUM(itd_deductible_recovery_expense_reserve_amt) AS itd_deductible_recovery_expense_reserve_amt,
                SUM(reinsurance_recovery_expense_reserve_amt) AS reinsurance_recovery_expense_reserve_amt,
                SUM(itd_reinsurance_recovery_expense_reserve_amt) AS itd_reinsurance_recovery_expense_reserve_amt,
                SUM(overpayment_recovery_expense_reserve_amt) AS overpayment_recovery_expense_reserve_amt,
                SUM(itd_overpayment_recovery_expense_reserve_amt) AS itd_overpayment_recovery_expense_reserve_amt,
                SUM(subrogation_recovery_defense_reserve_amt) AS subrogation_recovery_defense_reserve_amt,
                SUM(itd_subrogation_recovery_defense_reserve_amt) AS itd_subrogation_recovery_defense_reserve_amt,
                SUM(salvage_recovery_defense_reserve_amt) AS salvage_recovery_defense_reserve_amt,
                SUM(itd_salvage_recovery_defense_reserve_amt) AS itd_salvage_recovery_defense_reserve_amt,
                SUM(deductible_recovery_defense_reserve_amt) AS deductible_recovery_defense_reserve_amt,
                SUM(itd_deductible_recovery_defense_reserve_amt) AS itd_deductible_recovery_defense_reserve_amt,
                SUM(reinsurance_recovery_defense_reserve_amt) AS reinsurance_recovery_defense_reserve_amt,
                SUM(itd_reinsurance_recovery_defense_reserve_amt) AS itd_reinsurance_recovery_defense_reserve_amt,
                SUM(overpayment_recovery_defense_reserve_amt) AS overpayment_recovery_defense_reserve_amt,
                SUM(itd_overpayment_recovery_defense_reserve_amt) AS itd_overpayment_recovery_defense_reserve_amt,
                SUM(defense_paid_amt) AS defense_paid_amt,
                SUM(itd_defense_paid_amt) AS itd_defense_paid_amt,
                SUM(deductible_recovery_amt) AS deductible_recovery_amt,
                SUM(itd_deductible_recovery_amt) AS itd_deductible_recovery_amt,
                SUM(reinsurance_recovery_amt) AS reinsurance_recovery_amt,
                SUM(itd_reinsurance_recovery_amt) AS itd_reinsurance_recovery_amt,
                SUM(overpayment_recovery_amt) AS overpayment_recovery_amt,
                SUM(itd_overpayment_recovery_amt) AS itd_overpayment_recovery_amt,
                SUM(deductible_expense_recovery_amt) AS deductible_expense_recovery_amt,
                SUM(itd_deductible_expense_recovery_amt) AS itd_deductible_expense_recovery_amt,
                SUM(reinsurance_expense_recovery_amt) AS reinsurance_expense_recovery_amt,
                SUM(itd_reinsurance_expense_recovery_amt) AS itd_reinsurance_expense_recovery_amt,
                SUM(overpayment_expense_recovery_amt) AS overpayment_expense_recovery_amt,
                SUM(itd_overpayment_expense_recovery_amt) AS itd_overpayment_expense_recovery_amt,
                SUM(subrogation_defense_recovery_amt) AS subrogation_defense_recovery_amt,
                SUM(itd_subrogation_defense_recovery_amt) AS itd_subrogation_defense_recovery_amt,
                SUM(salvage_defense_recovery_amt) AS salvage_defense_recovery_amt,
                SUM(itd_salvage_defense_recovery_amt) AS itd_salvage_defense_recovery_amt,
                SUM(deductible_defense_recovery_amt) AS deductible_defense_recovery_amt,
                SUM(itd_deductible_defense_recovery_amt) AS itd_deductible_defense_recovery_amt,
                SUM(reinsurance_defense_recovery_amt) AS reinsurance_defense_recovery_amt,
                SUM(itd_reinsurance_defense_recovery_amt) AS itd_reinsurance_defense_recovery_amt,
                SUM(overpayment_defense_recovery_amt) AS overpayment_defense_recovery_amt,
                SUM(itd_overpayment_defense_recovery_amt) AS itd_overpayment_defense_recovery_amt,
			source_system_sk,@current_date AS update_ts,@etl_audit_sk
			FROM
				edw_core.tclaim_feature_summary 
			WHERE month_sk=@end_dt_sk
			GROUP BY month_sk, claim_sk, product_sk, policy_sk, broker_sk, customer_sk,source_system_sk
		
			SET @rows_affected=@@ROWCOUNT

			UPDATE tclaim_summary
			SET
			itd_loss_incurred_gt_250k_ct=(CASE WHEN itd_total_incurred_amt>250000 THEN 1 ELSE 0 END),
			itd_loss_incurred_gt_500k_ct=(CASE WHEN itd_total_incurred_amt>500000 THEN 1 ELSE 0 END),
			claim_closed_with_pay_ct=(CASE WHEN closed_claim_ct=1 AND
             (
                itd_total_paid_amt  - defense_paid_amt - expense_paid_amt - subrogation_recovery_amt - salvage_recovery_amt -salvage_expense_recovery_amt-subrogation_expense_recovery_amt-
				deductible_recovery_amt-reinsurance_recovery_amt-overpayment_recovery_amt-deductible_expense_recovery_amt-
			    reinsurance_expense_recovery_amt-overpayment_expense_recovery_amt-subrogation_defense_recovery_amt-
		        salvage_defense_recovery_amt-deductible_defense_recovery_amt-reinsurance_defense_recovery_amt- overpayment_defense_recovery_amt
                )>0 THEN 1 ELSE 0 END),
			claim_closed_without_pay_ct=(CASE WHEN closed_claim_ct=1 AND 
            (
                itd_total_paid_amt  - defense_paid_amt - expense_paid_amt -
                subrogation_recovery_amt - salvage_recovery_amt -salvage_expense_recovery_amt-subrogation_expense_recovery_amt-
				deductible_recovery_amt-reinsurance_recovery_amt-overpayment_recovery_amt-deductible_expense_recovery_amt-
			    reinsurance_expense_recovery_amt-overpayment_expense_recovery_amt-subrogation_defense_recovery_amt-
		        salvage_defense_recovery_amt-deductible_defense_recovery_amt-reinsurance_defense_recovery_amt- overpayment_defense_recovery_amt
            )=0 THEN 1 ELSE 0 END)
			
			WHERE month_sk=@end_dt_sk;

			-- Update control table
			IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
			BEGIN
				select 	@end_dt = max(actual_dt)
				from edw_core.tdate
				where yearmonth = @yearmonth and actual_dt <= cast(getdate() as date); 
			END
			SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts); 	
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

			SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
			FETCH NEXT FROM cur_main INTO @yearmonth, @begin_dt_sk ,@end_dt_sk , @begin_dt, @end_dt;
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