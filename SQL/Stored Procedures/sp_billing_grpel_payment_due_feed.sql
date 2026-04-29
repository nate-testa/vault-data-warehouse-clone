
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 04/29/2026
-- Description: This procedures inserts workday reserve data
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/29/2026		Yunus Mohammed				1. Created this procedure
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
			select
				gmc.grpel_master_policy_no,
				gmc.insured_nm,
				gmc.effective_dt,
				gmc.expiration_dt,
				sum(pt.premium_amt) as premium_amt
			from
				edw_core.tgrpel_master_coverage gmc
				inner join edw_core.tpolicy p on gmc.grpel_master_policy_no = p.grpel_master_policy_no
				inner join edw_core.tpolicy_transaction pt on p.policy_sk = pt.policy_sk
			group by gmc.grpel_master_policy_no, gmc.insured_nm, gmc.effective_dt,  gmc.expiration_dt
		)
              

		INSERT INTO edw_integration.billing_grpel_payment_due_feed
		(
			company,group_account,group_name,effective_date,expiration_date,payor_type,product,total_premium,payments_made,balance_due_as_of_month_end,
            month_end,create_ts,update_ts,etl_audit_sk
		)		
		select
			'Vault E & S Insurance Company' as company,
			bap.grpel_master_policy_no as group_account,
			pt.insured_nm as group_name,
			pt.effective_dt as effective_date,
			pt.expiration_dt as expiration_date,
			bap.bill_type as payor_type,
			'Group Personal Excess Liability' as product,
			pt.premium_amt as total_premium,
			sum(bap.payment_amt) as payments_made,
			pt.premium_amt - sum(bap.payment_amt) as balance_due_as_of_month_end,
			@last_day_month AS month_end,
			GETDATE() as create_ts,
			GETDATE() as update_ts,
			@etl_audit_sk as etl_audit_sk
		from
			billing_grpel_payment_due_feed_temp as pt
			inner join edw_core.tbilling_account_payment bap on bap.grpel_master_policy_no = pt.grpel_master_policy_no
		group by bap.grpel_master_policy_no, pt.insured_nm, pt.effective_dt,  pt.expiration_dt, bap.bill_type,pt.premium_amt
		
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