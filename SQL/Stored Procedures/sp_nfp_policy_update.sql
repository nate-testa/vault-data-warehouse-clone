-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
--
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tnfp_policy_pp]
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

		DROP TABLE IF EXISTS edw_temp.tnfp_policy_pp_temp1;		
		WITH temp_nfp_base_1 as (
		select FIRST_VALUE(effective_date) OVER (PARTITION BY insured_cert_no ORDER BY effective_date) as effective_date_new,
		np.* 
		FROM edw_stage.nfp_policy np
		WHERE insured_cert_no is not null and insured_first_name is not null and insured_last_name is not null and address1 is not null and zip is not null 
		and np.reporting_month > @last_source_extract_ts
		),
		temp_nfp_base_2 AS (
		SELECT  
			np.*,
			RANK() OVER (
				PARTITION BY insured_first_name, insured_last_name, address1, zip 
				ORDER BY expiration_date
			) AS rn,
			row_number() over (partition by insured_cert_no
					order by 
						effective_date_new,
						transaction_date,
						case 
							when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
							when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
							else 1 
						end
				) - 1 as transaction_seq_no,
			CASE 
				WHEN insured_cert_no = LAG(insured_cert_no) OVER (
					PARTITION BY insured_first_name, insured_last_name, address1, zip
					ORDER BY expiration_date
				) THEN NULL 
				ELSE LAG(insured_cert_no) OVER (
					PARTITION BY insured_first_name, insured_last_name, address1, zip 
					ORDER BY expiration_date
				) 
			END AS prior_policy_no,
			row_number() over (
				partition by insured_cert_no
				order by 
					effective_date_new desc,
					transaction_date desc,
					case 
						when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
						when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
						else 1 
					end desc
			) as latest_trans_rn
		FROM temp_nfp_base_1 np
		)
		select 
		reporting_month
		,group_name
		,policy_no
		,insured_cert_no
		,risk_state
		,insured_first_name
		,insured_last_name
		,insured_spouse_first_name
		,insured_spouse_last_name
		,address1
		,address2
		,city
		,state
		,zip
		,enroll_date
		,effective_date as effective_date_org
		,expiration_date
		,transaction_date
		,transaction_type,
		---- new cols
		effective_date_new as effective_date,
		transaction_seq_no,
		case when latest_trans_rn = 1 then 'Y' else 'N' end as latest_trans,
		case when rn = 1 then null 
		else FIRST_VALUE(insured_cert_no) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as original_policy_no,
		case when rn = 1 then null 
		else FIRST_VALUE(effective_date) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as original_policy_effective_dt,
		LAST_VALUE(prior_policy_no) IGNORE NULLS OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) as prior_term_policy_no,
		case when rn = 1 then null 
		else FIRST_VALUE(effective_date) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as uw_company_original_policy_effective_dt,
		@ssk as source_system_sk
		----
		,surplus_line_lic_no
		,program_administrator_fees_no
		,surplus_lines_tax
		,total_collected
		,written_prem_without_tax
		,nfppc_commission
		,net_premium
		,surcharged_premium
		,group_excess_liability_coverage
		,group_excess_liability_coverage_premium
		,uninsured_motorist_liability_coverage
		,uninsured_motorist_liability_premium
		,employment_practises_liability_coverage
		,employment_practises_liability_premium
		,[non_profit_d&o_liability_coverage]
		,[non_profit_d&o_liability_premium]
		,family_trust_management_liability_coverage
		,family_trust_management_liability_premium
		,number_of_residences
		,number_of_vehicles
		,number_of_drivers_under_22
		,number_of_drivers_from_22_to_75
		,number_of_drivers_76_and_older
		,underlying_auto_liability_limit
		,underlying_home_liability_limit
		,underlying_watercraft_liability_limit
		,underinsured_liability_limit
		,nfp_program_sharing_funding
		,vault_fronting_fees_xol_cc_collected
		,qs_cc_collected
		,total_cc_collected
		,nfp_commission_paid
		,vault_cc_override_after_expenses
		,vault_fronting_fees
		,add_fee_income_due
		,vault_prem_w_profitshare_frontfees
		,risk_group
		,create_ts
		,update_ts
		,product_type
		,product_nm
		,fronting_fee_total
		,underwriting_year_percentage
		into edw_temp.tnfp_policy_pp_temp1
		from temp_nfp_base_2 np;
			
		-- Start Insert process
		INSERT INTO edw_core.tnfp_policy_pp (
			reporting_month
			,group_name
			,policy_no
			,insured_cert_no
			,risk_state
			,insured_first_name
			,insured_last_name
			,insured_spouse_first_name
			,insured_spouse_last_name
			,address1
			,address2
			,city
			,state
			,zip
			,enroll_date
			,effective_date_org
			,expiration_date
			,transaction_date
			,transaction_type
			,effective_date
			,transaction_seq_no
			,latest_trans
			,original_policy_no
			,original_policy_effective_dt
			,prior_term_policy_no
			,uw_company_original_policy_effective_dt
			,source_system_sk
			,surplus_line_lic_no
			,program_administrator_fees_no
			,surplus_lines_tax
			,total_collected
			,written_prem_without_tax
			,nfppc_commission
			,net_premium
			,surcharged_premium
			,group_excess_liability_coverage
			,group_excess_liability_coverage_premium
			,uninsured_motorist_liability_coverage
			,uninsured_motorist_liability_premium
			,employment_practises_liability_coverage
			,employment_practises_liability_premium
			,[non_profit_d&o_liability_coverage]
			,[non_profit_d&o_liability_premium]
			,family_trust_management_liability_coverage
			,family_trust_management_liability_premium
			,number_of_residences
			,number_of_vehicles
			,number_of_drivers_under_22
			,number_of_drivers_from_22_to_75
			,number_of_drivers_76_and_older
			,underlying_auto_liability_limit
			,underlying_home_liability_limit
			,underlying_watercraft_liability_limit
			,underinsured_liability_limit
			,nfp_program_sharing_funding
			,vault_fronting_fees_xol_cc_collected
			,qs_cc_collected
			,total_cc_collected
			,nfp_commission_paid
			,vault_cc_override_after_expenses
			,vault_fronting_fees
			,add_fee_income_due
			,vault_prem_w_profitshare_frontfees
			,risk_group
			,create_ts_org
			,update_ts_org
			,product_type
			,product_nm
			,fronting_fee_total
			,underwriting_year_percentage
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT 
			reporting_month
			,group_name
			,policy_no
			,insured_cert_no
			,risk_state
			,insured_first_name
			,insured_last_name
			,insured_spouse_first_name
			,insured_spouse_last_name
			,address1
			,address2
			,city
			,state
			,zip
			,enroll_date
			,effective_date_org
			,expiration_date
			,transaction_date
			,transaction_type
			,effective_date
			,transaction_seq_no
			,latest_trans
			,original_policy_no
			,original_policy_effective_dt
			,prior_term_policy_no
			,uw_company_original_policy_effective_dt
			,source_system_sk
			,surplus_line_lic_no
			,program_administrator_fees_no
			,surplus_lines_tax
			,total_collected
			,written_prem_without_tax
			,nfppc_commission
			,net_premium
			,surcharged_premium
			,group_excess_liability_coverage
			,group_excess_liability_coverage_premium
			,uninsured_motorist_liability_coverage
			,uninsured_motorist_liability_premium
			,employment_practises_liability_coverage
			,employment_practises_liability_premium
			,[non_profit_d&o_liability_coverage]
			,[non_profit_d&o_liability_premium]
			,family_trust_management_liability_coverage
			,family_trust_management_liability_premium
			,number_of_residences
			,number_of_vehicles
			,number_of_drivers_under_22
			,number_of_drivers_from_22_to_75
			,number_of_drivers_76_and_older
			,underlying_auto_liability_limit
			,underlying_home_liability_limit
			,underlying_watercraft_liability_limit
			,underinsured_liability_limit
			,nfp_program_sharing_funding
			,vault_fronting_fees_xol_cc_collected
			,qs_cc_collected
			,total_cc_collected
			,nfp_commission_paid
			,vault_cc_override_after_expenses
			,vault_fronting_fees
			,add_fee_income_due
			,vault_prem_w_profitshare_frontfees
			,risk_group
			,create_ts
			,update_ts
			,product_type
			,product_nm
			,fronting_fee_total
			,underwriting_year_percentage
			,getdate()
			,getdate()
			,@etl_audit_sk
		FROM 
			edw_temp.tnfp_policy_pp_temp1;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.tnfp_policy_pp_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tnfp_policy_pp_temp1;
		
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

