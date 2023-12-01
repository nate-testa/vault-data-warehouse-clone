-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 10/20/2023
-- Description: This procedures insert OneShied policy into tpolicy transaction table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tpolicy_transaction]

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

		DROP TABLE IF EXISTS edw_temp.os_tpolicy_transaction_temp1

		SELECT
		tp.policy_sk,
		tdeff.date_sk AS effective_dt_sk,
		tdexp.date_sk AS expiration_dt_sk,
		tdtrxexp.date_sk AS transaction_effective_dt_sk,
		pt.policy_trx_seq_num AS transaction_seq_no,
		tb.broker_sk,
		tcust.customer_sk,
		pt.policy_trx_premium_chg AS premium_amt,
		f.premium_amount AS net_premium_amt,
		fc.premium_amount AS commission_amt,
		0 as annual_premium_amt,
		fm.premium_amount AS tax_fee_surcharge_amt,
		0 as item_sk,0 AS coverage_sk,0 AS vehicle_coverage_sk,
		td.date_sk AS transaction_dt_sk,
		tdac.date_sk AS calendar_month_sk,
		tdac.date_sk AS accouting_month_sk,
		tprd.product_sk,
		-- pt.policy_trx_type_name,
		tptt.policy_transaction_type_sk,
		null as internal_coverage_sk,tps.policy_status_sk,
		null as tax_fee_surcharge_sk,NULL AS user_sk,1 as source_system_sk
		INTO edw_temp.os_tpolicy_transaction_temp1
		FROM
		edw_stage.dragon_policy p
		inner join edw_stage.dragon_policy_trx pt ON p.policy_id=pt.policy_id
		inner JOIN edw_core.tpolicy tph on tph.policy_no = pt.policy_trx_policy_number and tph.source_system_sk = 1
		left join edw_core.tpolicy tp on  tp.policy_no = pt.policy_trx_policy_number  -- tp.policy_no=p.policy_number
		left join edw_core.tproduct tprd on tprd.product_cd=tp.product_cd
		INNER JOIN edw_core.tbroker tb ON tb.broker_id=pt.policy_trx_partner_id
		LEFT JOIN edw_core.tcustomer tcust on tcust.customer_id=pt.customer_id
		left join edw_core.tdate tdeff on tdeff.actual_dt=cast(pt.policy_trx_image_eff_date as date)
		left join edw_core.tdate tdexp on tdexp.actual_dt=cast(pt.policy_trx_image_exp_date as date)
		left join edw_core.tdate tdtrxexp on tdtrxexp.actual_dt=cast(pt.policy_trx_eff_date as date)		
		left join edw_core.tdate td on td.actual_dt= GREATEST(cast(pt.policy_trx_process_date as date),cast(pt.policy_trx_eff_date as date))
		left join edw_core.tdate tdac on tdac.yearmonth=td.yearmonth and tdac.month_end_in='Y'
		left join edw_core.tpolicy_status tps on tps.policy_status_cd = 
		CASE
		WHEN p.policy_object_state_name IN('Active','Created','Rewritten') THEN 'Active'
		WHEN p.policy_object_state_name IN('Cancelled','Non Renewed','Expired','PendingCancel') THEN 'Cancelled'
		END
		left join 
		(
			select policy_transaction_id, sum(initial_amount) as premium_amount
			from edw_stage.dragon_fitem 
			where category = 'Premium' and account_holder_name not like 'Vault%' and policy_no is not null
			group by policy_transaction_id
		) f on pt.policy_trx_id=f.policy_transaction_id
		left join 
		(
			select policy_transaction_id, sum(initial_amount) as premium_amount
			from edw_stage.dragon_fitem 
			where category = 'Commission' and account_holder_name not like 'Vault%' and policy_no is not null
			group by policy_transaction_id
		) fc on pt.policy_trx_id=fc.policy_transaction_id
		left join 
		(
			select policy_transaction_id, sum(initial_amount) as premium_amount
			from edw_stage.dragon_fitem 
			where category = 'Member Surplus Contribution' and account_holder_name not like 'Vault%' and policy_no is not null
			group by policy_transaction_id
		) fm on pt.policy_trx_id=fm.policy_transaction_id
		left join edw_core.tpolicy_transaction_type AS tptt ON
		tptt.policy_transaction_type_cd = 	CASE
			WHEN pt.policy_trx_type_name in
			( 'Pending Cancellation',
			'Rescind Pending Cancellation',
			'Invoice',
			'Change Payment Plan',
			'Audit',
			'Intent to Non-Renew',
			'Late Notice',
			'Non-Renewal',
			'First Reminder Notice'
			)
			THEN 'NON-PREMIUM'
			WHEN pt.policy_trx_type_name in
			(
			'Rewrite',
			'New Business Rewrite',
			'New Business'
			) THEN 'POLICY'
			WHEN
			pt.policy_trx_type_name in
			(
			'Cancellation',
			'Cancellation - Insured'
			) THEN 'CANCELLATION'	
			WHEN
			pt.policy_trx_type_name in
			(
			'Premium/Non Premium',
			'Endorsement'
			) THEN 'ADDITIONAL PREMIUM'
			WHEN pt.policy_trx_type_name='Renewal' THEN 'RENEWAL'
			WHEN pt.policy_trx_type_name='Rollback' THEN 'RETURN PREMIUM'
			WHEN pt.policy_trx_type_name='Reinstatement' THEN 'REINSTATEMENT'
			END
		WHERE
			tp.policy_sk IS NOT NULL
			AND pt.policy_trx_process_date IS NOT NULL			
		
		INSERT INTO edw_core.tpolicy_transaction
		(
		policy_sk,effective_dt_sk,expiration_dt_sk,transaction_effective_dt_sk,transaction_seq_no,broker_sk,
		customer_sk,premium_amt,net_premium_amt,commission_amt,annual_premium_amt,tax_fee_surcharge_amt,
		item_sk,coverage_sk,vehicle_coverage_sk,transaction_dt_sk,calendar_month_sk,accouting_month_sk,
		product_sk,policy_transaction_type_sk,internal_coverage_sk,policy_status_sk,
		tax_fee_surcharge_sk,user_sk,source_system_sk,create_ts,update_ts,etl_audit_sk
		-- ceded_premium_amt
		-- ceded_annual_premium_amt
		)
		SELECT
			policy_sk,effective_dt_sk,expiration_dt_sk,transaction_effective_dt_sk,transaction_seq_no,broker_sk,
			customer_sk,premium_amt,net_premium_amt,commission_amt,annual_premium_amt,tax_fee_surcharge_amt,
			item_sk,coverage_sk,vehicle_coverage_sk,transaction_dt_sk,calendar_month_sk,accouting_month_sk,
			product_sk,policy_transaction_type_sk,internal_coverage_sk,policy_status_sk,
			tax_fee_surcharge_sk,user_sk,
			source_system_sk,GETDATE() AS create_ts,GETDATE() update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tpolicy_transaction_temp1
			
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts= '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tpolicy_transaction_temp1
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