-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
--
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_nfp]
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

		DROP TABLE IF EXISTS edw_temp.tpolicy_nfp_temp1;
		WITH temp_nfp_base AS (
		SELECT np.*,
			ROW_NUMBER() OVER (PARTITION BY insured_cert_no, term_effective_date 
						ORDER BY transaction_seq_no DESC) AS AccountTransaction_Rank,
			case when np.product_type = 'Group Umbrella' then 'Group Personal Excess Liability' else np.product_type end as product_name	
		FROM edw_stage.nfp_policy np
		WHERE np.reporting_month > @last_source_extract_ts
		and insured_cert_no is not null
		)
		,temp_cust_info AS (
			SELECT * 
			FROM (
				SELECT 
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
		,nfp_tpol as (
		SELECT insured_cert_no	as	policy_no,
			   term_effective_date	as	effective_dt,
			   expiration_date	as	expiration_dt,
			   '56601' as broker_id,
			   tc.customer_id,
			   pr.product_cd, 
			   risk_state	as	risk_state_cd,
			   insured_first_name + ' ' + insured_last_name	as	insured_nm,
			   policy_term,
			   null as latest_term_in,
			   'Vault E & S Insurance Company'	as	uw_company_nm,
			   'Non-Admitted'	as	program_type,
			   null as	policy_status, 
			   case when cast(transaction_type as varchar(60)) like 'Cancel%' and transaction_date  >  term_effective_date then transaction_date
				 when cast(transaction_type as varchar(60)) like 'Cancel%' and transaction_date  <=  term_effective_date then term_effective_date end as cancellation_effective_dt,
			   np.original_policy_no,
			   np.original_policy_effective_dt,
			   address1 AS mailing_address_line1,
			   address2 AS mailing_address_line2,
			   city AS mailing_address_city_nm,
			   state AS mailing_address_state_cd,
			   zip AS mailing_address_zip_cd,
			   np.prior_term_policy_no,
			   'No' as migrated_in,
			   'No' as rewritten_in,
			   'No' as oneshield_migrated_in,
			   np.term_no,
			   null as lifetime_claim_ct, 
			   null as lifetime_loss_incurred_amt, 
			   np.uw_company_original_policy_effective_dt,			   
			   reporting_month
		FROM temp_nfp_base np
		LEFT JOIN temp_cust_info tc ON 
			UPPER(np.insured_first_name) = UPPER(tc.first_nm) AND
			UPPER(np.insured_last_name) = UPPER(tc.last_nm) AND
			UPPER(np.address1) = UPPER(tc.mailing_address_line1) AND
			np.zip = tc.mailing_address_zip_cd
		LEFT JOIN edw_core.tproduct pr ON 
			np.product_name = pr.product_nm
		where np.AccountTransaction_Rank = 1)
		select policy_no, effective_dt, expiration_dt, broker_id, customer_id, product_cd, risk_state_cd, insured_nm, policy_term, 
			latest_term_in, uw_company_nm, program_type, policy_status, cancellation_effective_dt, original_policy_no, original_policy_effective_dt,
			mailing_address_line1, mailing_address_line2, mailing_address_city_nm, mailing_address_state_cd, mailing_address_zip_cd, prior_term_policy_no, 
			migrated_in, rewritten_in, term_no, lifetime_claim_ct, lifetime_loss_incurred_amt, uw_company_original_policy_effective_dt, reporting_month,oneshield_migrated_in 
		into edw_temp.tpolicy_nfp_temp1
		from nfp_tpol 
		;
				
		-- Start Insert process
		MERGE [edw_core].[tpolicy] AS Target
		USING edw_temp.tpolicy_nfp_temp1 AS Source
		ON Source.policy_no = Target.policy_no
		   AND cast(Source.effective_dt as date) = cast(Target.effective_dt as date)
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			policy_no,
			effective_dt,
			expiration_dt,
			broker_id,
			customer_id,
			product_cd,
			risk_state_cd,
			insured_nm,
			insured_type,
			policy_term,
			latest_term_in,
			uw_company_nm,
			program_type,
			policy_status,
			cancellation_effective_dt,
			original_policy_no,
			original_policy_effective_dt,
			mailing_address_line1,
			mailing_address_line2,
			mailing_address_unit_no,
			mailing_address_city_nm,
			mailing_address_state_cd,
			mailing_address_zip_cd,
			mailing_address_county_nm,
			mailing_address_country_nm,
			non_renewal_in,
			prior_policy_no,
			billingaccount_sk,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk,
			prior_term_policy_no,
			pending_non_renewal_in,
			conditional_renewal_in,
			non_renewal_note_desc,
			non_renewal_sub_note_desc,
			migrated_in,
			oneshield_migrated_in,
			rewritten_in,
			term_no,
			lifetime_claim_ct,
			lifetime_loss_incurred_amt,
			uw_company_original_policy_effective_dt,
			target_account,
			document_delivery_to,
			document_delivery_method,
			renewal_cap_factor,
			billing_paid_in,
			bound_by_broker_in
		)
		VALUES (
			Source.policy_no,
			Source.effective_dt,
			Source.expiration_dt,
			Source.broker_id,
			Source.customer_id,
			Source.product_cd,
			Source.risk_state_cd,
			Source.insured_nm,
			NULL,
			Source.policy_term,
			Source.latest_term_in,
			Source.uw_company_nm,
			Source.program_type,
			Source.policy_status,
			Source.cancellation_effective_dt,
			Source.original_policy_no,
			Source.original_policy_effective_dt,
			Source.mailing_address_line1,
			Source.mailing_address_line2,
			NULL,
			Source.mailing_address_city_nm,
			Source.mailing_address_state_cd,
			Source.mailing_address_zip_cd,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			@ssk,
			GETDATE(),
			GETDATE(),
			@etl_audit_sk,
			Source.prior_term_policy_no,
			NULL,
			NULL,
			NULL,
			NULL,
			Source.migrated_in,
			Source.oneshield_migrated_in,
			Source.rewritten_in,
			Source.term_no,
			Source.lifetime_claim_ct,
			Source.lifetime_loss_incurred_amt,
			Source.uw_company_original_policy_effective_dt,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
		)
		WHEN MATCHED THEN UPDATE SET
			Target.expiration_dt                         = Source.expiration_dt,
			Target.broker_id                             = Source.broker_id,
			Target.customer_id                           = Source.customer_id,
			Target.product_cd                            = Source.product_cd,
			Target.risk_state_cd                         = Source.risk_state_cd,
			Target.insured_nm                            = Source.insured_nm,
			Target.policy_term                           = Source.policy_term,
			Target.latest_term_in                        = Source.latest_term_in,
			Target.uw_company_nm                         = Source.uw_company_nm,
			Target.program_type                          = Source.program_type,
			Target.policy_status                         = Source.policy_status,
			Target.cancellation_effective_dt             = Source.cancellation_effective_dt,
			Target.original_policy_no                    = Source.original_policy_no,
			Target.original_policy_effective_dt          = Source.original_policy_effective_dt,
			Target.mailing_address_line1                 = Source.mailing_address_line1,
			Target.mailing_address_line2                 = Source.mailing_address_line2,
			Target.mailing_address_city_nm               = Source.mailing_address_city_nm,
			Target.mailing_address_state_cd              = Source.mailing_address_state_cd,
			Target.mailing_address_zip_cd                = Source.mailing_address_zip_cd,
			Target.prior_term_policy_no                  = Source.prior_term_policy_no,
			Target.migrated_in                           = Source.migrated_in,
			Target.oneshield_migrated_in                 = Source.oneshield_migrated_in,
			Target.rewritten_in                          = Source.rewritten_in,
			Target.term_no                               = Source.term_no,
			Target.lifetime_claim_ct                     = Source.lifetime_claim_ct,
			Target.lifetime_loss_incurred_amt            = Source.lifetime_loss_incurred_amt,
			Target.uw_company_original_policy_effective_dt = Source.uw_company_original_policy_effective_dt,
			Target.source_system_sk                      = @ssk,
			Target.update_ts                             = GETDATE();

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.tpolicy_nfp_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tpolicy_nfp_temp1;
		
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