-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert OneShied policy into tpolicy table
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/20/23			Yunus Mohammed					1. Created this procedure
-- 12/15/23			Yunus Mohammed					2. Updated program_type logic
-- 04/15/24			Yunus Mohammed					3. Updated logic for original policy no and effective date
-- 06/28/24			Yunus Mohammed					4. Updated logic for policy_term
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tpolicy]

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

		DROP TABLE IF EXISTS edw_temp.os_tpolicy_temp1

		SELECT policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,
		policy_term,uw_company_nm,program_type,policy_status,cancellation_effective_dt,original_policy_no,original_policy_effective_dt,
		mailing_address_line1,mailing_address_line2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
		mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,non_renewal_in,prior_policy_no,billingaccount_id,
		1 as source_system_sk
		INTO edw_temp.os_tpolicy_temp1
		FROM
		(
		SELECT
		--	top 10000
			ROW_NUMBER() OVER (PARTITION BY trx.policy_trx_policy_number ORDER BY trx.policy_trx_seq_num DESC) rn,
			trx.policy_trx_policy_number as policy_no,
			trx.policy_trx_image_eff_date as effective_dt,
			trx.policy_trx_image_exp_date as expiration_dt,
			tbrk.broker_id as broker_id,
			tcust.customer_id as customer_id,
			CASE 
			WHEN trx.POLICY_TRX_LOB_NAME IN ('Vault Home Complete','Homeowners') then 'HO'
			WHEN trx.POLICY_TRX_LOB_NAME IN ('Vault Lux Collections','Collections') then 'LUX'
			WHEN trx.POLICY_TRX_LOB_NAME IN ('Vault Lux Collections','Excess Liability') then 'PEL'
			ELSE trx.policy_trx_lob_name END as product_cd,
			CASE
				WHEN tst.state_cd IS NOT NULL THEN tst.state_cd
				WHEN trx.policy_trx_risk_state='Washington, D.C.' THEN 'DC'
				ELSE trx.policy_trx_risk_state
			END as risk_state_cd,
			trx.policy_trx_insured_name as insured_nm,
			null as insured_type,
			case when trx.policy_rank = 1 then 'New'
			else 'Renewal' end as policy_term,
			case
				when p.writing_company_name='Vault Reciprocal Exchange' then 'Vault Reciprocal Exchange'
				when p.writing_company_name='Vault E&S Insurance Company' then 'Vault E & S Insurance Company'
			   -- when trx.policy_trx_policy_program='non-admitted' then 'vault e & s insurance company'
			   -- when trx.policy_trx_policy_program='admitted' then 'vault reciprocal exchange'
			   else
				p.writing_company_name
			end as uw_company_nm,
			-- trx.policy_trx_policy_program as program_type,
			case
			when p.writing_company_name='Vault Reciprocal Exchange' then 'Admitted'
			when p.writing_company_name='Vault E&S Insurance Company' then 'Non-Admitted'
			end as program_type,
		ptrm.policy_term_pas_status as policy_status,
		case when trx.policy_trx_type_name='cancellation' then trx.policy_trx_image_eff_date else null end as cancellation_effective_dt,
		(
			SELECT TOP 1 trx1.policy_trx_policy_number FROM edw_stage.dragon_policy_trx trx1
			WHERE
				trx1.policy_id = trx.policy_id
				and trx1.policy_trx_policy_number is not null
			ORDER BY trx1.policy_trx_seq_num
		)  as original_policy_no,
		(
			SELECT TOP 1 trx1.policy_trx_image_eff_date FROM edw_stage.dragon_policy_trx trx1
			WHERE
				trx1.policy_id = trx.policy_id
				and trx1.policy_trx_image_eff_date is not null
			ORDER BY trx1.policy_trx_seq_num
		)  as original_policy_effective_dt,
		ba.address_line1 as mailing_address_line1,
		null as mailing_address_line2,
		null as mailing_address_unit_no,
		ba.address_city as mailing_address_city_nm,
		ba.address_state as mailing_address_state_cd,
		ba.address_zip_code as mailing_address_zip_cd,
		null as mailing_address_county_nm,
		ba.address_country as mailing_address_country_nm,
		CASE WHEN trx.policy_renewal_hold_indicator='T' then 'Yes' Else 'No' END AS non_renewal_in,
		null as prior_policy_no,
		ba.billingaccount_id
		FROM
			edw_stage.dragon_policy p
			INNER JOIN
			(
				SELECT dense_rank()over(partition by policy_id order by policy_trx_policy_number) as policy_rank,*
				FROM
					edw_stage.dragon_policy_trx trx
				WHERE
					trx.policy_trx_process_date IS NOT NULL
					AND trx.policy_trx_policy_number IS NOT NULL
					AND trx.policy_trx_risk_state IS NOT NULL
			) AS trx ON p.policy_id = trx.policy_id
			LEFT JOIN edw_stage.dragon_policy_term ptrm on ptrm.policy_term_id=trx.policy_term_id
			LEFT JOIN (SELECT DISTINCT policy_transaction_id,billing_account_id from edw_stage.dragon_fitem f) f on trx.policy_trx_id = f.policy_transaction_id
			LEFT JOIN edw_stage.dragon_billingaccount ba on ba.billingaccount_id = f.billing_account_id
			LEFT JOIN edw_core.tbroker tbrk on tbrk.broker_id=cast(trx.policy_trx_partner_id as varchar(255))
			LEFT JOIN edw_core.tcustomer tcust on tcust.customer_id=cast(trx.customer_id as varchar(255))
			LEFT JOIN edw_core.tpolicy tph on tph.policy_no = trx.policy_trx_policy_number
			LEFT JOIN edw_core.tstate tst on tst.state_nm = trx.policy_trx_risk_state
		WHERE
			tbrk.broker_id IS NOT NULL
			AND tph.policy_sk is null
		) a
		WHERE rn=1
		
		INSERT INTO [edw_core].[tpolicy]
		(
		policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,policy_term,
		uw_company_nm,program_type,policy_status,cancellation_effective_dt,original_policy_no,original_policy_effective_dt,
		mailing_address_line1,mailing_address_line2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
		mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,non_renewal_in,prior_policy_no,
		billingaccount_sk,source_system_sk,create_ts,update_ts,etl_audit_sk
		-- ,latest_term_in
		)
		SELECT
			policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,
			policy_term,uw_company_nm,program_type,policy_status,cancellation_effective_dt,original_policy_no,original_policy_effective_dt,
			mailing_address_line1,mailing_address_line2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
			mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,non_renewal_in,prior_policy_no,NULL billingaccount_id,
			source_system_sk,GETDATE() AS create_ts,GETDATE() update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tpolicy_temp1
			
		SET @rows_affected=@@ROWCOUNT;

		
		update tp
		SET
			tp.product_cd = 'AU'
		FROM
		edw_core.tpolicy tp
		inner join 
		(
			select product,policy_number
			from edw_stage.OneShieldPolicy 
			where
			product='Auto'
			group by product,policy_number
		) as osp on osp.policy_number = tp.policy_no
		where
		tp.source_system_sk = 1
		
		-- Update control table
		SET @new_last_source_extract_ts= '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tpolicy_temp1
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