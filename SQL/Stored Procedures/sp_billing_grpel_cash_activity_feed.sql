
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 04/29/2026
-- Description: This procedures inserts workday reserve data
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/29/2026		Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_billing_grpel_cash_activity_feed]
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

		DELETE FROM edw_integration.billing_grpel_cash_activity_feed
        WHERE month_end = @last_day_month; 
		
		WITH billing_grpel_cash_activity_feed_temp AS
		(
            select 
                'Vault E & S Insurance Company' as company,
                bap.grpel_master_policy_no as group_account,
                gmc.insured_nm as group_name,
                gmc.effective_dt as effective_date,
                gmc.expiration_dt as expiration_date,
                bap.bill_type as payor_type,
                'Group Personal Excess Liability' as product,
                bap.payment_from_type as payment_from,
                bap.receivable_cd as category,
                bap.payment_method as paid_via,
                bap.user_remark reference_code,
                bap.payment_dt as payment_date,
                bap.payment_amt as amount,
                @last_day_month AS month_end,
                GETDATE() as create_ts,
                GETDATE() as update_ts,
				@etl_audit_sk as etl_audit_sk
                from
                    edw_core.tbilling_account_payment bap
                    inner join edw_core.tgrpel_master_coverage gmc on bap.grpel_master_policy_no = gmc.grpel_master_policy_no
                    and gmc.transaction_seq_no = 
                                            (
                                                select max(transaction_seq_no)
                                                from
                                                    edw_core.tgrpel_master_coverage gmc1
                                                where
                                                    gmc1.grpel_master_policy_no = gmc.grpel_master_policy_no
                                            )
        )
              

		INSERT INTO edw_integration.billing_grpel_cash_activity_feed
		(
            company,group_account,group_name,effective_date,expiration_date,payor_type,product,payment_from,category,paid_via,reference_code,payment_date,amount,
            month_end,create_ts,update_ts,etl_audit_sk
		)
		SELECT
            company,group_account,group_name,effective_date,expiration_date,payor_type,product,payment_from,category,paid_via,reference_code,payment_date,amount,
            month_end,create_ts,update_ts,etl_audit_sk
		FROM
			billing_grpel_cash_activity_feed_temp
		
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