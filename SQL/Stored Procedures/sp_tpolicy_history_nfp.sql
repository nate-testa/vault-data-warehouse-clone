-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date  |Author						        |	Change Description
------------------------------------------------------------------------------------------------------------
-- 08/22/2023   Dinesh Bobbili						1. Created this procedure 
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
		select np.*,row_number() over (
			partition by insured_cert_no
			order by 
				effective_date,
				transaction_date,
				case 
					when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
					when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
					else 1 
				end
		) - 1 as transaction_seq_no,
		row_number() over (
			partition by insured_cert_no
			order by 
				effective_date,
				transaction_date,
				case 
					when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
					when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
					else 1 
				end desc
		) as rn,
		case when cast(transaction_type as varchar(60)) in ('New', 'Renewal') and np.transaction_date >= np.effective_date then np.effective_date
				when (cast(transaction_type as varchar(60)) like 'Endorsement%' or cast(transaction_type as varchar(60)) like 'Cancel%')
				and np.transaction_date > np.effective_date then np.transaction_date
				when cast(transaction_type as varchar(60)) in ('New', 'Renewal') and np.transaction_date <= np.effective_date then np.effective_date
				when (cast(transaction_type as varchar(60)) like 'Endorsement%' or cast(transaction_type as varchar(60)) like 'Cancel%')
				and np.transaction_date <= np.effective_date then np.effective_date end as transaction_effective_dt,
		cast(transaction_type as varchar(60)) as transaction_type_2
		from  edw_stage.nfp_policy np
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
		select insured_cert_no	as	policy_no,
			effective_date	as	effective_dt,
			expiration_date	as	expiration_dt,
			transaction_effective_dt,
			np.transaction_seq_no as transaction_seq_no,
			case when rn = 1 then 'Y' else 'N' end as latest_transaction_in,
			tp.policy_sk	as	policy_sk,
			318 as broker_sk,
			tc.customer_sk,
			pr.product_sk,
			'56601' as broker_id, 
			tc.customer_id,
			case when transaction_type_2 ='New' then 'New'
					when transaction_type_2 = 'Renewal' then 'Renewal'
					when transaction_type_2 like 'Endorsement%' then 'Endorsement'
					when transaction_type_2 like 'Cancel%' then 'Cancelled' end as transaction_type,
			np.transaction_date as transaction_ts,
			np.total_collected as premium_amt,
			written_prem_without_tax as	net_premium_amt,
			program_administrator_fees_no + surplus_lines_tax	as	tax_fee_surcharge_amt,
			nfp_commission_paid	as	commission_amt,
			ROUND(total_collected* 365.0 / NULLIF(DATEDIFF(DAY, np.transaction_effective_dt, np.expiration_date), 0), 2) as annual_premium_amt,
			nfp_commission_paid/written_prem_without_tax	as	commission_pc	,
			'Issued'	as	transaction_status
		into edw_temp.tpolicy_history_nfp_temp1
		from temp_nfp_base np
		left join edw_core.tpolicy tp
		on np.insured_cert_no = tp.policy_no
			and np.effective_date = tp.effective_dt
		left join temp_cust_info tc
			on  upper(np.insured_first_name) = upper(tc.first_nm)
			and upper(insured_last_name) = upper(tc.last_nm)
			and upper(address1) = upper(tc.mailing_address_line1)
			and np.zip = tc.mailing_address_zip_cd
		left join edw_core.tproduct pr
			on np.product_type = pr.product_nm;
			
		-- Start Insert process
		INSERT INTO edw_core.tpolicy_history (
			policy_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,latest_transaction_in
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
			,latest_transaction_in
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

