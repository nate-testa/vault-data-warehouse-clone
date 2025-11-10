-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
--
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_history_nfp]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DECLARE @ssk VARCHAR(50)
		select @ssk=source_system_sk from edw_core.tsource_system where source_system_nm = 'NFP';

		DROP TABLE IF EXISTS edw_temp.tpolicy_history_nfp_temp1;
		with temp_nfp_base as 
		(
		SELECT
			np.insured_cert_no,
			np.term_effective_date,
			np.expiration_date,
			np.insured_first_name,
			np.insured_last_name,
			np.address1,
			np.zip,
			np.product_type,
			np.transaction_seq_no,
			np.transaction_date,
			np.reporting_month,
			np.effective_date as transaction_effective_dt,
			case when np.product_type = 'Group Umbrella' then 'Group Personal Excess Liability' else np.product_type end as product_name,
			CAST(transaction_type AS VARCHAR(60)) AS transaction_type_2,

			ROW_NUMBER() OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
				ORDER BY 
					np.transaction_seq_no DESC
			) AS dup_rn,

			SUM(np.written_prem_without_tax) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS written_prem_without_tax,

			SUM(np.program_administrator_fees_no) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS program_administrator_fees_no,

			SUM(np.surplus_lines_tax) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS surplus_lines_tax,

			SUM(np.nfp_commission_paid) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS nfp_commission_paid,
			
			SUM(np.nfppc_commission) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS nfppc_commission,

			SUM(np.total_collected) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS total_collected
		FROM edw_stage.nfp_policy np
		where insured_cert_no is not null 
		and np.reporting_month > @last_source_extract_ts
		)
		,temp_cust_info AS (
			SELECT * 
			FROM (
				SELECT customer_sk,
					customer_id,
					np.insured_first_name AS first_nm,
					np.insured_last_name AS last_nm,
					np.address1 AS mailing_address_line1,
					np.zip AS mailing_address_zip_cd,
					ROW_NUMBER() OVER (
						PARTITION BY 
							np.insured_first_name,
							np.insured_last_name,
							np.address1,
							np.zip 
						ORDER BY tc.customer_sk DESC
					) AS cust_rn
				FROM temp_nfp_base np 
				LEFT JOIN edw_core.tcustomer tc ON 
					UPPER(np.insured_first_name) = UPPER(tc.first_nm) AND
					UPPER(np.insured_last_name) = UPPER(tc.last_nm) AND
					UPPER(np.address1) = UPPER(tc.mailing_address_line1) AND
					np.zip = tc.mailing_address_zip_cd
			) a 
			WHERE cust_rn = 1
		)
		select distinct  insured_cert_no	as	policy_no,
			term_effective_date	as	effective_dt,
			expiration_date	as	expiration_dt,
			transaction_effective_dt,
			np.transaction_seq_no as transaction_seq_no,
			tp.policy_sk	as	policy_sk,
			318 as broker_sk,
			tc.customer_sk,
			pr.product_sk,
			'56601' as broker_id, 
			tc.customer_id,
			case when transaction_type_2 ='New' then 'New'
					when transaction_type_2 = 'Renewal' then 'Renewal'
					when transaction_type_2 like 'Endorsement%' then 'Endorsement'
					-- Yunus: 11/05/2025
					when transaction_type_2 like 'Cancel%' then 'Cancellation' end as transaction_type,
			np.transaction_date as transaction_ts,
			np.total_collected as premium_amt,
			written_prem_without_tax as	net_premium_amt,
			program_administrator_fees_no + surplus_lines_tax	as	tax_fee_surcharge_amt,
			nfppc_commission	as	commission_amt,
			np.total_collected as annual_premium_amt,
			case when written_prem_without_tax <> 0 then nfp_commission_paid/written_prem_without_tax else 0 end	as	commission_pc	,
			'Issued'	as	transaction_status,
			reporting_month,
			DENSE_RANK() OVER(PARTITION BY insured_cert_no,term_effective_date ORDER BY transaction_seq_no DESC) AS rnk
		into edw_temp.tpolicy_history_nfp_temp1
		from temp_nfp_base np
		left join edw_core.tpolicy tp
		on np.insured_cert_no = tp.policy_no
			and np.term_effective_date = tp.effective_dt
		left join temp_cust_info tc
			on  upper(np.insured_first_name) = upper(tc.first_nm)
			and upper(insured_last_name) = upper(tc.last_nm)
			and upper(address1) = upper(tc.mailing_address_line1)
			and np.zip = tc.mailing_address_zip_cd
		left join edw_core.tproduct pr
			on np.product_name = pr.product_nm 
		WHERE dup_rn = 1;
			
		INSERT INTO edw_core.tpolicy_history (
			policy_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,policy_sk
			,broker_sk
			,customer_sk
			,product_sk
			,broker_id
			,customer_id
			,transaction_type
			,transaction_ts
			,premium_amt
			,net_premium_amt
			,tax_fee_surcharge_amt
			,commission_amt
			,annual_premium_amt			
			,commission_pc
			,transaction_status
			,source_system_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT 
			policy_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,policy_sk
			,broker_sk
			,customer_sk
			,product_sk
			,broker_id
			,customer_id
			,transaction_type
			,transaction_ts
			,premium_amt
			,net_premium_amt
			,tax_fee_surcharge_amt
			,commission_amt
			,annual_premium_amt
			,commission_pc
			,transaction_status
			,@ssk
			,getdate()
			,getdate()
			,@etl_audit_sk
		FROM 
			edw_temp.tpolicy_history_nfp_temp1;

		SET @rows_affected=@@ROWCOUNT;
		
		update h
		set latest_transaction_in = 'N'
		from edw_core.tpolicy_history h
		where exists (select 'x' from edw_temp.tpolicy_history_nfp_temp1 h1 where h.policy_no = h1.policy_no and h.effective_dt = h1.effective_dt);

		update h
		set latest_transaction_in = 'Y'
		from edw_core.tpolicy_history h
		where exists (select 'x' from edw_temp.tpolicy_history_nfp_temp1 h1 
					  where h.policy_no = h1.policy_no 
					  and h.effective_dt = h1.effective_dt
					  and h.transaction_seq_no = h1.transaction_seq_no and h1.rnk = 1);

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.tpolicy_history_nfp_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tpolicy_history_nfp_temp1;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END