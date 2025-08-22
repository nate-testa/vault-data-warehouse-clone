-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date  |Author						        |	Change Description
------------------------------------------------------------------------------------------------------------
-- 08/22/2023   Dinesh Bobbili						1. Created this procedure 
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
		select np.*,
		case when cast(transaction_type as varchar(60)) in ('New', 'Renewal') and np.transaction_date >= np.effective_date then np.effective_date
						when (cast(transaction_type as varchar(60)) like 'Endorsement%' or cast(transaction_type as varchar(60)) like 'Cancel%')
						and np.transaction_date > np.effective_date then np.transaction_date
						when cast(transaction_type as varchar(60)) in ('New', 'Renewal') and np.transaction_date <= np.effective_date then np.effective_date
						when (cast(transaction_type as varchar(60)) like 'Endorsement%' or cast(transaction_type as varchar(60)) like 'Cancel%')
						and np.transaction_date <= np.effective_date then np.effective_date end as transaction_effective_dt,
		row_number() over (
					partition by insured_cert_no
					order by 
						effective_date,
						transaction_date,
						case 
							when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
							when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
							else 1 
						end
				) - 1 as transaction_seq_no
			,cast(transaction_type as varchar(60)) as transaction_type_2
		from edw_stage.nfp_policy np
		where insured_cert_no is not null and insured_first_name is not null and insured_last_name is not null and address1 is not null and zip is not null 
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
			ROUND(total_collected* 365.0 / NULLIF(DATEDIFF(DAY, np.transaction_effective_dt, np.expiration_date), 0), 2) as annual_premium_amt, -- 365 --> calc no of days b/n expiration_date - term_effective_date
			program_administrator_fees_no + surplus_lines_tax as tax_fee_surcharge_amt,
			0 as item_sk,
			uc.group_umbrella_coverage_sk as coverage_sk,
			0 as vehicle_coverage_sk,
			dt3.date_sk as transaction_dt_sk,
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) calendar_month_sk, 
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) accounting_month_sk,
			pr.product_sk,
			case when transaction_type_2 ='New' then 1
				when transaction_type_2 like 'Endorsement%'  and total_collected > 0 then 2
				when transaction_type_2 like 'Endorsement%'  and total_collected < 0 then 3
				when transaction_type_2 like 'Endorsement%'  and total_collected = 0 then 4
				when transaction_type_2 like 'Cancel%' then 5
				when transaction_type_2 = 'Renewal' then 7 end as policy_transaction_type_sk,
			0	as	internal_coverage_sk,
			case when transaction_type_2 like 'Cancel%'	then 2 else 1 end as policy_status_sk, 
			0	as	tax_fee_surcharge_sk,
			0	as	user_sk,
			0	as	ceded_premium_amt,
			0	as	ceded_annual_premium_amt,
			0	as	collection_class_type_sk,
			polh.policy_history_sk,
			np.reporting_month
		into edw_temp.tpolicy_transaction_nfp_temp1
		from temp_nfp_base np 
		left join edw_core.tpolicy pol 
			on np.insured_cert_no = pol.policy_no and cast(np.effective_date as date) = pol.effective_dt
		left join edw_core.tdate dt1 
			on dt1.actual_dt = cast(np.effective_date as date)
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
		left join edw_core.tgroup_umbrella_coverage uc 
			on  np.insured_cert_no = uc.policy_no and cast(np.effective_date as date) = uc.effective_dt and np.transaction_seq_no = uc.transaction_seq_no
		left join edw_core.tproduct pr
						on np.product_type = pr.product_nm
		left join edw_core.tpolicy_history polh on polh.policy_no = np.insured_cert_no and polh.effective_dt = cast(np.effective_date as date)  and polh.transaction_seq_no = np.transaction_seq_no;

			
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
		)
		SELECT 
			policy_no
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
			,accounting_month_sk
			,product_sk
			,policy_transaction_type_sk
			,internal_coverage_sk
			,@ssk
			,policy_status_sk
			,tax_fee_surcharge_sk
			,user_sk
			,getdate()
			,getdate()
			,@etl_audit_sk
			,ceded_premium_amt
			,ceded_annual_premium_amt
			,collection_class_type_sk
			,policy_history_sk
		FROM 
			edw_temp.tpolicy_transaction_nfp_temp1

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