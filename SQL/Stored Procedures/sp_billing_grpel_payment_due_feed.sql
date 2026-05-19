
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 04/29/2026
-- Description: This procedures inserts workday reserve data
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/29/2026		Yunus Mohammed				1. Created this procedure
-- 05/14/2026		Yunus Mohammed				2. AD-13382- Added group_minimum_premium,broker_commission
--														and renamed some columns
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_billing_grpel_payment_due_feed]
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

		DECLARE @last_day_month DATE, @year_month INT;
		select @year_month = yearmonth
		from edw_core.tdate
		where
			actual_dt > case
								when datediff(dd,@last_source_extract_ts,@current_date) = 1 then dateadd(dd,-1,@last_source_extract_ts)
								else @last_source_extract_ts
							end
			and actual_dt < cast(@current_date as date)
		group by yearmonth
		order by 1;	
		
		SELECT @last_day_month = actual_dt FROM edw_core.tdate WHERE yearmonth = @year_month and month_end_in = 'Y';

		DELETE FROM edw_integration.billing_grpel_payment_due_feed
        WHERE month_end = @last_day_month; 
		
		WITH billing_grpel_payment_due_feed_temp AS
		(
			SELECT
				gmc.grpel_master_policy_no,
				gmc.insured_nm,
				gmc.effective_dt,
				gmc.expiration_dt,
				sum(pt.premium_amt) as premium_amt
			FROM
				edw_core.tgrpel_master_coverage gmc
				INNER JOIN edw_core.tpolicy p ON gmc.grpel_master_policy_no = p.grpel_master_policy_no
				INNER JOIN edw_core.tpolicy_transaction pt ON p.policy_sk = pt.policy_sk
			GROUP BY gmc.grpel_master_policy_no, gmc.insured_nm, gmc.effective_dt,  gmc.expiration_dt
		)
              

		INSERT INTO edw_integration.billing_grpel_payment_due_feed
		(
			company,group_account,group_name,effective_date,expiration_date,payor_type,product,total_participant_premium,
			payments_received,net_amount_due_to_vault,group_minimum_premium,broker_commission,
            month_end,create_ts,update_ts,etl_audit_sk
		)		
		SELECT
			'Vault E & S Insurance Company' as company,
			pivottable.grpel_master_policy_no as group_account,
			pivottable.insured_nm as group_name,
			pivottable.effective_dt as effective_date, 
			pivottable.expiration_dt as expiration_date,
			bap.bill_type as payor_type,
			'Group Personal Excess Liability' as [product],
			pivottable.premium_amt as total_participant_premium,
			sum(bap.payment_amt) as payments_received,
			pivottable.premium_amt - sum(bap.payment_amt) -(cast(pivottable.MinimumPremium as decimal(15,2)) * cast(pivottable.CommissionPercentage as decimal(15,2)) /100.00) as net_amount_due_to_vault,
			pivottable.MinimumPremium as group_minimum_premium,
			(cast(pivottable.MinimumPremium as decimal(15,2)) * cast(pivottable.CommissionPercentage as decimal(15,2)) /100.00) as broker_commission,
			@last_day_month AS month_end,
			GETDATE() as create_ts,
			GETDATE() as update_ts,
			@etl_audit_sk as etl_audit_sk
		FROM
		(
		SELECT
			pt.grpel_master_policy_no,
			pt.insured_nm,
			pt.effective_dt,
			pt.expiration_dt,
			pt.premium_amt,
			accof.Field,
			accof.[Value]
		FROM
		billing_grpel_payment_due_feed_temp as pt
		INNER JOIN edw_stage.Account acc ON acc.PolicyNumber = pt.grpel_master_policy_no
				and acc.EffectiveDate  = pt.effective_dt
		INNER JOIN edw_stage.AccountObject acco ON acc.Id = acco.AccountId
		INNER JOIN edw_stage.AccountObjectField accof ON acco.Id = accof.ObjectId
		and accof.Field in ('MinimumPremium','CommissionPercentage')
		) as t

		pivot 
		(
			max(Value) FOR Field IN 
			(      
			MinimumPremium,CommissionPercentage
			)
		) as pivottable
		inner join edw_core.tbilling_account_payment bap on bap.grpel_master_policy_no = pivottable.grpel_master_policy_no
		group by pivottable.grpel_master_policy_no, pivottable.insured_nm, pivottable.effective_dt,  pivottable.expiration_dt, 
		bap.bill_type,pivottable.premium_amt,pivottable.MinimumPremium,pivottable.CommissionPercentage
		
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts =dateadd(day,-1,cast(@current_date as date))
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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