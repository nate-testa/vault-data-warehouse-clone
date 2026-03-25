-- =======================================================================================================================================================
-- Description: This procedures updates tquote
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 07/02/25		Dinesh Bobbili				1. Created this procedure  
-- 07/03/25		Dinesh Bobbili				2. Added condition on effective_dt
-- 08/20/25		Dinesh Bobbili				3. Updated logic for billing_paid_in and added logic for first_billing_payment_dt
-- 01/27/26		Yunus Mohammed		 		4. AD-12386 Added transaction_type PAYMENT_ADJUSTMENT
-- 01/28/26		Yunus Mohammed		 		5. AD-12386 Removed delta identifier. Now we are doing full update.
-- 03/24/26		Yunus Mohammed		 		5. AD-12718 Used edw_stage.stage_majesco_payment_data_feed table instead of 
--													edw_stage.stage_majesco_cash_activity
-- ======================================================================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_billing_paid_in_update]

AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET ANSI_WARNINGS OFF
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
		drop table if exists edw_temp.tpolicy_billing_paid_in_update_temp1;

		WITH payment_totals AS 
		(
			SELECT 
				pf.policy_no,
				cast(tf.policy_eff_date as date) as policy_eff_date,
				pf.system_activity_no,
				CAST(pf.created_on AS date) AS txn_date,
				SUM(v.payment_amount_num) AS total_payment_amount
			FROM edw_stage.stage_majesco_payment_data_feed pf
			CROSS APPLY (
				SELECT TRY_CONVERT(
						decimal(18,2),
						NULLIF(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(LTRIM(RTRIM(pf.payment_amount)), '$', ''), 
									',', ''), 
								'(', '-'), 
							')', ''), 
						'')
					) AS payment_amount_num
			) v
			, edw_stage.stage_majesco_transaction_data_feed tf 
			WHERE cast(created_on as date) >= '2024-01-01'
			AND pf.receivable_code = 'PREMIUM'
			AND pf.transaction_type IN ('PAYMENT', 'PAYMENT_TRANSFER_INTERNAL', 'PAYMENT_ADJUSTMENT')
			and pf.account_no = tf.account_no
			and pf.policy_no = tf.policy_no
			and pf.system_activity_no = tf.system_activity_no
			GROUP BY pf.policy_no, cast(tf.policy_eff_date as date), pf.system_activity_no, pf.system_activity_no, CAST(pf.created_on AS date)
		)

		SELECT policy_no, txn_date, total_payment_amount
		INTO edw_temp.tpolicy_billing_paid_in_update_temp1
		FROM (
			SELECT a.*,
				ROW_NUMBER() OVER (PARTITION BY a.policy_no, a.policy_eff_date ORDER BY txn_date ASC) AS rn
			FROM payment_totals a, edw_core.tpolicy b 
			WHERE a.policy_no = b.policy_no
			and a.policy_eff_date = b.effective_dt 
			AND b.billing_paid_in IS NULL
		) t
		WHERE rn = 1
		AND total_payment_amount < 0 

		update a
		SET
			billing_paid_in = 'Yes'
		from
			edw_core.tpolicy a,
			edw_temp.tpolicy_billing_paid_in_update_temp1 b
		where
			a.policy_no = b.policy_no			
			AND a.billing_paid_in IS NULL	
			
		UPDATE a
		SET a.first_billing_payment_dt = b.txn_date
		from
			edw_core.tpolicy a,
			edw_temp.tpolicy_billing_paid_in_update_temp1 b
		where
			a.policy_no = b.policy_no
			and a.first_billing_payment_dt is null;

		SET @rows_affected=@@ROWCOUNT;
	
		--SET @new_last_source_extract_ts=COALESCE((SELECT MAX(txn_date) FROM edw_temp.tpolicy_billing_paid_in_update_temp1),@last_source_extract_ts); 
		SET @new_last_source_extract_ts = '2017-01-01';
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

		drop table if exists edw_temp.tpolicy_billing_paid_in_update_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

GO