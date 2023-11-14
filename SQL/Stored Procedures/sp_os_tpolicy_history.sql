/****** Object:  StoredProcedure [edw_core].[sp_os_tpolicy_history]    Script Date: 11-11-2023 00:02:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/06/2023
-- Description: This procedures insert OneShied policy history into tpolicy_history table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tpolicy_history]

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

		DROP TABLE IF EXISTS edw_temp.os_tpolicy_history_temp1;

		WITH os_tpolicy_history AS
		(
		SELECT
		ROW_NUMBER() OVER (PARTITION BY trx.policy_trx_policy_number ORDER BY trx.policy_trx_seq_num desc) rn,
		trx.policy_id,
		trx.policy_trx_id,
		trx.policy_trx_policy_number as policy_no,
		trx.policy_trx_image_eff_date as effective_dt,
		trx.policy_trx_image_exp_date as expiration_dt,
		trx.policy_trx_eff_date as transaction_effective_dt,
		trx.policy_trx_seq_num as transaction_seq_no,
		'n' as latest_transaction_in,
		-- latest_transaction_in 'y' or 'n'
		tp.policy_sk,
		tbrk.broker_sk,
		trx.policy_trx_partner_id AS broker_id,
		tcust.customer_sk,
		trx.customer_id AS customer_id,
		CASE 
				WHEN trx.policy_trx_lob_name = 'Vault Home Complete' then 'Homeowners'
				WHEN trx.policy_trx_lob_name = 'Vault Lux Collections' then 'Collections'
				ELSE trx.policy_trx_lob_name END AS product_cd,
		CASE WHEN trx.policy_trx_type_name LIKE 'Cancel%' and trx.cancellation_reason LIKE 'Policy Rew%' 
					THEN 'Cancellation - Rewrite'
			WHEN trx.policy_trx_type_name LIKE 'Cancel%' 
			THEN 'Cancellation - ' + trx.cancellation_reason
			ELSE trx.policy_trx_type_name
		END AS transaction_type,
		trx.policy_trx_description AS transaction_desc, 
		trx.policy_trx_creation_date AS transaction_ts,
		trx.cancellation_reason AS cancelltion_reason_desc,
		trx.policy_trx_premium_chg AS premium_amt,
		trx.policy_trx_risk_state AS risk_state_cd,
		trx.policy_trx_insured_name AS insured_nm,
		trx.policy_trx_type_name AS polict_term, -- some transformation may require
		CASE
			WHEN trx.policy_trx_policy_program='Non-Admitted' THEN 'Vault E & S Insurance Company'
			WHEN trx.policy_trx_policy_program='Admitted' THEN 'Vault Reciprocal Exchange'
		END AS uw_company_nm,
		trx.policy_trx_policy_program AS program_type,
		ptrm.policy_term_pas_status AS policy_status,
		CASE WHEN trx.policy_trx_type_name='Cancellation' THEN trx.policy_trx_image_eff_date ELSE NULL END AS cancellation_effective_dt,
		trx.cancellation_reason AS cancellation_reason_desc,
		fpre.net_premium_amt,
		fpre.tax_fee_surcharge_amt,
		fpre.commission_amt,
		trx.policy_trx_producer_name AS producer_nm,
		trx.policy_trx_uw_name AS underwriter_nm ,
		ba.address_line1 AS mailing_address_line1,
		NULL AS mailing_address_line2,
		NULL AS mailing_address_unit_no,
		ba.address_city AS mailing_address_city_nm,    
		ba.address_state AS mailing_address_state_cd,
		ba.address_zip_code AS mailing_address_zip_cd,
		NULL AS mailing_address_county_nm,
		ba.address_country AS mailing_address_country_nm,
		trx.policy_renewal_hold_indicator,
		NULL AS prior_policy_no,
		p.billing_account_number,
		tprd.product_sk
		FROM
		edw_stage.dragon_policy p
		INNER JOIN edw_stage.dragon_policy_trx trx ON p.policy_id = trx.policy_id
		LEFT JOIN 
		(
			SELECT
				policy_transaction_id,
				SUM(CASE WHEN Category='Premium' THEN initial_amount ELSE 0 END) AS net_premium_amt,
				SUM(CASE WHEN Category='Member Surplus Contribution' THEN initial_amount ELSE 0 END) AS tax_fee_surcharge_amt,
				SUM(CASE WHEN Category='Commission' THEN initial_amount ELSE 0 END) AS commission_amt
			FROM edw_stage.dragon_fitem fpre
			WHERE
				Category IN( 'Premium','Member Surplus Contribution', 'Commission')
			GROUP BY policy_transaction_id
		) AS fpre ON fpre.policy_transaction_id = trx.policy_trx_id
		LEFT JOIN edw_stage.dragon_policy_term ptrm ON ptrm.policy_term_id=trx.policy_term_id -- trx.policy_id = ptrm.policy_id
		LEFT JOIN 
		(
			SELECT DISTINCT policy_transaction_id,billing_account_id FROM edw_stage.dragon_fitem f
			WHERE category = 'Premium' and account_holder_name not like 'Vault%' and policy_no is not null 
	
		) f ON trx.policy_trx_id = f.policy_transaction_id
		LEFT JOIN (SELECT * FROM edw_stage.dragon_billingaccount ba WHERE ba.account_type='Customer') AS ba ON ba.billingaccount_id = f.billing_account_id
		LEFT JOIN edw_core.tbroker tbrk ON tbrk.broker_id=trx.policy_trx_partner_id
		LEFT JOIN edw_core.tcustomer tcust ON tcust.customer_id=trx.customer_id
		LEFT JOIN edw_core.tpolicy tp ON tp.policy_no=trx.policy_trx_policy_number
		LEFT JOIN edw_core.tproduct tprd ON tprd.product_cd = tp.product_cd
		WHERE
			trx.policy_trx_process_date IS NOT NULL
			and trx.policy_trx_policy_number IS NOT NULL
			AND tbrk.broker_id IS NOT NULL
			AND trx.policy_trx_risk_state IS NOT NULL
			AND trx.policy_trx_processed_tf = '1'
		)
		-- trx.policy_trx_policy_number ORDER BY trx.policy_trx_seq_num desc
		SELECT DISTINCT
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,
			CASE WHEN otph.transaction_seq_no=(SELECT MAX(transaction_seq_no) FROM os_tpolicy_history otph1 
				WHERE otph1.policy_no = otph.policy_no
			) THEN 'Y' ELSE 'N' END AS latest_transaction_in,
			policy_sk,broker_sk,customer_sk,broker_id,customer_id,transaction_type,transaction_ts,transaction_desc,
			cancelltion_reason_desc,premium_amt,net_premium_amt,tax_fee_surcharge_amt,commission_amt,
			null as annual_premium_amt,null as transaction_initiated_by,null as transaction_issued_by,
			underwriter_nm,producer_nm,null as product_sk,null as policy_change_summary,null as commission_pc,
			null as override_commission_pc,null as commission_retention
		INTO edw_temp.os_tpolicy_history_temp1
		FROM
		os_tpolicy_history otph
		-- SELECT * FROM edw_temp.os_tpolicy_history_temp1
		
		INSERT INTO [edw_core].[tpolicy_history]
		(
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,latest_transaction_in,
			policy_sk,broker_sk,customer_sk,broker_id,customer_id,transaction_type,transaction_ts,transaction_desc,
			cancellation_reason_desc,premium_amt,net_premium_amt,tax_fee_surcharge_amt,commission_amt,
			annual_premium_amt,transaction_initiated_by,transaction_issued_by,underwriter_nm,producer_nm,
			product_sk,policy_change_summary,commission_pc,override_commission_pc,commission_retention,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,
			latest_transaction_in,policy_sk,broker_sk,
			customer_sk,broker_id,customer_id,transaction_type,transaction_ts,transaction_desc,
			cancelltion_reason_desc,premium_amt,net_premium_amt,tax_fee_surcharge_amt,commission_amt,
			null as annual_premium_amt,null as transaction_initiated_by,null as transaction_issued_by,
			underwriter_nm,producer_nm,null as product_sk,null as policy_change_summary,null as commission_pc,
			null as override_commission_pc,null as commission_retention,
			1 AS source_system_sk,GETDATE() AS create_ts,GETDATE() update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tpolicy_history_temp1
			
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts= '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tpolicy_history_temp1
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