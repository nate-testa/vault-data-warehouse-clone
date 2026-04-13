-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 11/10/25					Dinesh Bobbili				1. Created this procedure  
-- 12/17/25					Dinesh Bobbili				2. Updated logic for tax_fee_surcharge_sk 
-- 03/17/26					Yunus Mohammed				3. Ad-12820 - Removed error.
-- 04/08/26					Yunus Mohammed				2. AD-13063 Modified to use NFP customers only
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_transaction_nfp]
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

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_nfp_temp1;
		with temp_nfp_base as 
		(
		select np.insured_cert_no,
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
			
			SUM(np.nfppc_commission) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS nfppc_commission,

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

			SUM(np.total_collected) OVER (
				PARTITION BY 
					np.insured_cert_no,
					np.term_effective_date,
					np.transaction_seq_no
			) AS total_collected
		from edw_stage.nfp_policy np
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
				WHERE
					tc.customer_id LIKE 'NFP%'
			) a 
			WHERE cust_rn = 1
		)
		select pol.policy_sk,
			dt1.date_sk as effective_dt_sk,
			dt2.date_sk as expiration_dt_sk,
			dt4.date_sk as transaction_effective_dt_sk,
			np.transaction_seq_no,
			318 as broker_sk,
			tc.customer_sk,
			np.total_collected as premium_amt,
			np.written_prem_without_tax as net_premium_amt,
			np.nfppc_commission as commission_amt,
			np.total_collected as annual_premium_amt, 
			np.surplus_lines_tax,
			np.program_administrator_fees_no,
			program_administrator_fees_no + surplus_lines_tax as tax_fee_surcharge_amt,
			0 as item_sk,
			uc.grpel_coverage_sk as coverage_sk,
			0 as vehicle_coverage_sk,
			dt3.date_sk as transaction_dt_sk,
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where actual_dt = np.reporting_month)) as calendar_month_sk, 
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where actual_dt = np.reporting_month)) accounting_month_sk,
			pr.product_sk,
			case when transaction_type_2 ='New' then 1
				when transaction_type_2 like 'Endorsement%'  and total_collected > 0 then 2
				when transaction_type_2 like 'Endorsement%'  and total_collected < 0 then 3
				when transaction_type_2 like 'Endorsement%'  and total_collected = 0 then 4
				when transaction_type_2 like 'Cancel%' then 5
				when transaction_type_2 = 'Renewal' then 7 end as policy_transaction_type_sk,
			--yunus: 11/05/2025
			ic.internal_coverage_sk,
			case when transaction_type_2 like 'Cancel%'	then 2 else 1 end as policy_status_sk, 
			--0	as	tax_fee_surcharge_sk,
			0	as	user_sk,
			0	as	ceded_premium_amt,
			0	as	ceded_annual_premium_amt,
			0	as	collection_class_type_sk,
			polh.policy_history_sk,
			np.reporting_month,
			-- Yunus: 11/05/2025
			0 as state_premium_amt,
			0 as state_annual_premium_amt
		into edw_temp.tpolicy_transaction_nfp_temp1
		from temp_nfp_base np 		
		left join edw_core.tpolicy pol 
			on np.insured_cert_no = pol.policy_no and cast(np.term_effective_date as date) = pol.effective_dt
		left join edw_core.tdate dt1 
			on dt1.actual_dt = cast(np.term_effective_date as date)
		left join edw_core.tdate dt2 
			on dt2.actual_dt = cast(np.expiration_date as date)
		left join edw_core.tdate dt3
			on dt3.actual_dt = cast(np.transaction_date as date)
		left join edw_core.tdate dt4
			on dt4.actual_dt = cast(np.transaction_effective_dt as date)
		left join edw_core.tdate dt5
			on dt5.actual_dt = cast(iif(np.transaction_effective_dt > np.transaction_date, np.transaction_effective_dt, np.transaction_date) as date)
		left join temp_cust_info tc
					on  upper(np.insured_first_name) = upper(tc.first_nm)
					and upper(np.insured_last_name) = upper(tc.last_nm)
					and upper(np.address1) = upper(tc.mailing_address_line1)
					and np.zip = tc.mailing_address_zip_cd
		left join edw_core.tgrpel_coverage uc 
			on  np.insured_cert_no = uc.policy_no and cast(np.term_effective_date as date) = uc.effective_dt and np.transaction_seq_no = uc.transaction_seq_no
		left join edw_core.tproduct pr
						on np.product_name = pr.product_nm
		left join edw_core.tpolicy_history polh on polh.policy_no = np.insured_cert_no and polh.effective_dt = cast(np.term_effective_date as date)  and polh.transaction_seq_no = np.transaction_seq_no
		--yunus: 11/05/2025
		left join edw_core.tinternal_coverage ic on 
		ic.internal_coverage_cd = 
									CASE
									WHEN uc.excess_liability_limit_amt IS NOT NULL THEN 'Excess Liability' 
									WHEN uc.uninsured_motorist_liability_limit_amt IS NOT NULL THEN 'UM/UIM Motorist Liability' 
									WHEN uc.employment_practises_liability_limit_amt IS NOT NULL THEN 'Employment Practices Liability'
									ELSE 'Excess Liability'
									END
		and ic.product_cd ='GRPEL'
		WHERE dup_rn = 1;
			
		-- Start Insert process
		INSERT INTO edw_core.tpolicy_transaction (
			policy_sk
			,effective_dt_sk
			,expiration_dt_sk
			,transaction_effective_dt_sk
			,transaction_seq_no
			,broker_sk
			,customer_sk
			,premium_amt
			,net_premium_amt
			,commission_amt
			,annual_premium_amt
			,tax_fee_surcharge_amt
			,item_sk
			,coverage_sk
			,vehicle_coverage_sk
			,transaction_dt_sk
			,calendar_month_sk
			,accouting_month_sk
			,product_sk
			,policy_transaction_type_sk
			,internal_coverage_sk
			,source_system_sk
			,policy_status_sk
			,tax_fee_surcharge_sk
			,user_sk
			,create_ts
			,update_ts
			,etl_audit_sk
			,ceded_premium_amt
			,ceded_annual_premium_amt
			,collection_class_type_sk
			,policy_history_sk
			-- Yunus: 11/05/2025
			,state_premium_amt
			,state_annual_premium_amt
		) 
		select policy_sk,effective_dt_sk,expiration_dt_sk,transaction_effective_dt_sk,transaction_seq_no,broker_sk,customer_sk,
		net_premium_amt as premium_amt,net_premium_amt as net_premium,commission_amt as comission_amt,net_premium_amt as annual_premium_amt,
		0 as tax_fee_surcharge_amt,
		item_sk,coverage_sk,vehicle_coverage_sk,transaction_dt_sk,
		calendar_month_sk,accounting_month_sk,product_sk,policy_transaction_type_sk,internal_coverage_sk,@ssk as source_system_sk,policy_status_sk,
		0 as tax_fee_surcharge_sk,
		user_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk,
		ceded_premium_amt,ceded_annual_premium_amt,collection_class_type_sk,policy_history_sk,
		state_premium_amt,state_annual_premium_amt 
		from edw_temp.tpolicy_transaction_nfp_temp1 t1

		union all

		select policy_sk,effective_dt_sk,expiration_dt_sk,transaction_effective_dt_sk,transaction_seq_no,broker_sk,customer_sk,
		surplus_lines_tax as premium_amt,0 as net_premium,0 as comission_amt,surplus_lines_tax as annual_premium_amt,
		surplus_lines_tax as tax_fee_surcharge_amt,
		item_sk,coverage_sk,vehicle_coverage_sk,transaction_dt_sk,
		calendar_month_sk,accounting_month_sk,product_sk,policy_transaction_type_sk,ic.internal_coverage_sk,@ssk as source_system_sk,policy_status_sk,
		case when  ic.internal_coverage_category_nm = 'Premium' then 0 else ic.internal_coverage_sk end as tax_fee_surcharge_sk,
		user_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk,
		ceded_premium_amt,ceded_annual_premium_amt,collection_class_type_sk,policy_history_sk,
		state_premium_amt,state_annual_premium_amt 
		from edw_temp.tpolicy_transaction_nfp_temp1 t1
		left join edw_core.tinternal_coverage ic on ic.internal_coverage_cd = 'Surplus Lines Tax' and ic.product_cd ='GRPEL'

		union all

		select policy_sk,effective_dt_sk,expiration_dt_sk,transaction_effective_dt_sk,transaction_seq_no,broker_sk,customer_sk,
		program_administrator_fees_no as premium_amt,0 as net_premium,0 as comission_amt,program_administrator_fees_no as annual_premium_amt,
		program_administrator_fees_no as tax_fee_surcharge_amt,
		item_sk,coverage_sk,vehicle_coverage_sk,transaction_dt_sk,
		calendar_month_sk,accounting_month_sk,product_sk,policy_transaction_type_sk,ic.internal_coverage_sk,@ssk as source_system_sk,policy_status_sk,
		case when  ic.internal_coverage_category_nm = 'Premium' then 0 else ic.internal_coverage_sk end as tax_fee_surcharge_sk,
		user_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk,
		ceded_premium_amt,ceded_annual_premium_amt,collection_class_type_sk,policy_history_sk,
		state_premium_amt,state_annual_premium_amt 
		from edw_temp.tpolicy_transaction_nfp_temp1 t1
		left join edw_core.tinternal_coverage ic on ic.internal_coverage_cd = 'Program Administrator Fees' and ic.product_cd ='GRPEL'


		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.tpolicy_transaction_nfp_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_nfp_temp1;
		
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