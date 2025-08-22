-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date  |Author						        |	Change Description
------------------------------------------------------------------------------------------------------------
-- 08/22/2023   Dinesh Bobbili						1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tgroup_umbrella_coverage]
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
		DROP TABLE IF EXISTS edw_temp.tgroup_umbrella_coverage_temp1;
		with temp_nfp_base as 
		(
		select np.*,
            row_number() over (partition by insured_cert_no
			order by 
				effective_date,
				transaction_date,
				case 
					when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
					when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
					else 1 
				end
		) - 1 as transaction_seq_no
		from  edw_stage.nfp_policy np
		where np.reporting_month > @last_source_extract_ts
		)
		SELECT 
			np.insured_cert_no AS policy_no,
			np.policy_no AS group_umbrella_policy_no,
			np.effective_date AS effective_dt,
			np.transaction_date AS transaction_effective_dt,
			np.expiration_date AS expiration_dt,
			np.transaction_date AS transaction_dt,
			np.transaction_seq_no AS transaction_seq_no,
			tph.policy_history_sk AS policy_history_sk,
			cast(np.group_name as varchar(255)) AS group_nm,
			np.insured_spouse_first_name + ' ' + insured_spouse_last_name AS insured_spouse_nm,
			np.group_excess_liability_coverage AS group_excess_liability_limit_amt,
			np.group_excess_liability_coverage_premium AS group_excess_liability_premium_amt,
			np.uninsured_motorist_liability_coverage AS uninsured_motorist_liability_limit_amt,
			np.uninsured_motorist_liability_premium AS uninsured_motorist_liability_premium_amt,
			cast(np.employment_practises_liability_coverage as varchar(255)) AS employment_practises_liability_limit_amt,
			np.employment_practises_liability_premium AS employment_practises_liability_premium_amt,
			cast(np.[non_profit_d&o_liability_coverage] as varchar(255)) AS non_profit_do_liability_limit_amt,
			np.[non_profit_d&o_liability_premium] AS non_profit_do_liability_premium_amt,
			np.family_trust_management_liability_coverage AS family_trust_management_liability_limit_amt,
			np.family_trust_management_liability_premium AS family_trust_management_liability_premium_amt,
			np.number_of_residences AS no_of_residences,
			np.number_of_vehicles AS no_of_vehicles,
			np.number_of_drivers_under_22 AS no_of_drivers_under_22,
			np.number_of_drivers_from_22_to_75 AS no_of_drivers_from_22_to_75,
			np.number_of_drivers_76_and_older AS no_of_drivers_76_and_older,
			cast(np.underlying_auto_liability_limit as nvarchar(MAX)) AS underlying_auto_liability_limit_amt,
			np.underlying_home_liability_limit AS underlying_home_liability_limit_amt,
			np.underlying_watercraft_liability_limit AS underlying_watercraft_liability_limit_amt,
			cast(np.underinsured_liability_limit as nvarchar(MAX)) AS underinsured_liability_limit_desc,
			np.nfp_program_sharing_funding AS nfp_program_sharing_funding_amt,
			np.vault_fronting_fees_xol_cc_collected AS vault_fronting_fees_excessofloss_ceding_comm_collected_amt,
			np.qs_cc_collected AS quota_share_ceding_comm_collected_amt,
			np.total_cc_collected AS total_ceding_comm_collected_amt,
			np.vault_cc_override_after_expenses AS vault_ceding_comm_override_after_expenses_amt,
			np.vault_fronting_fees AS vault_fronting_fees_amt,
			np.add_fee_income_due AS add_fee_income_due_amt,
			np.vault_prem_w_profitshare_frontfees AS vault_premium_with_profitshare_frontfees_amt,
			cast(np.risk_group as varchar(255)) AS risk_group,
			np.fronting_fee_total AS fronting_fee_total_amt,
			np.underwriting_year_percentage AS underwriting_year_pc,
			np.reporting_month
		INTO edw_temp.tgroup_umbrella_coverage_temp1
		FROM temp_nfp_base np
		inner join edw_core.tpolicy_history tph
			on np.insured_cert_no = tph.policy_no
			and np.effective_date = tph.effective_dt
			and np.transaction_seq_no = tph.transaction_seq_no
			
		-- Start Insert process 
		INSERT INTO edw_core.tgroup_umbrella_coverage (
			policy_no
			,group_umbrella_policy_no
			,effective_dt
			,transaction_effective_dt
			,expiration_dt
			,transaction_dt
			,transaction_seq_no
			,policy_history_sk
			,group_nm
			,insured_spouse_nm
			,group_excess_liability_limit_amt
			,group_excess_liability_premium_amt
			,uninsured_motorist_liability_limit_amt
			,uninsured_motorist_liability_premium_amt
			,employment_practises_liability_limit_amt
			,employment_practises_liability_premium_amt
			,non_profit_do_liability_limit_amt
			,non_profit_do_liability_premium_amt
			,family_trust_management_liability_limit_amt
			,family_trust_management_liability_premium_amt
			,no_of_residences
			,no_of_vehicles
			,no_of_drivers_under_22
			,no_of_drivers_from_22_to_75
			,no_of_drivers_76_and_older
			,underlying_auto_liability_limit_amt
			,underlying_home_liability_limit_amt
			,underlying_watercraft_liability_limit_amt
			,underinsured_liability_limit_desc
			,nfp_program_sharing_funding_amt
			,vault_fronting_fees_excessofloss_ceding_comm_collected_amt
			,quota_share_ceding_comm_collected_amt
			,total_ceding_comm_collected_amt
			,vault_ceding_comm_override_after_expenses_amt
			,vault_fronting_fees_amt
			,add_fee_income_due_amt
			,vault_premium_with_profitshare_frontfees_amt
			,risk_group
			,fronting_fee_total_amt
			,underwriting_year_pc
			,source_system_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT 
			policy_no
			,group_umbrella_policy_no
			,effective_dt
			,transaction_effective_dt
			,expiration_dt
			,transaction_dt
			,transaction_seq_no
			,policy_history_sk
			,group_nm
			,insured_spouse_nm
			,group_excess_liability_limit_amt
			,group_excess_liability_premium_amt
			,uninsured_motorist_liability_limit_amt
			,uninsured_motorist_liability_premium_amt
			,employment_practises_liability_limit_amt
			,employment_practises_liability_premium_amt
			,non_profit_do_liability_limit_amt
			,non_profit_do_liability_premium_amt
			,family_trust_management_liability_limit_amt
			,family_trust_management_liability_premium_amt
			,no_of_residences
			,no_of_vehicles
			,no_of_drivers_under_22
			,no_of_drivers_from_22_to_75
			,no_of_drivers_76_and_older
			,underlying_auto_liability_limit_amt
			,underlying_home_liability_limit_amt
			,underlying_watercraft_liability_limit_amt
			,underinsured_liability_limit_desc
			,nfp_program_sharing_funding_amt
			,vault_fronting_fees_excessofloss_ceding_comm_collected_amt
			,quota_share_ceding_comm_collected_amt
			,total_ceding_comm_collected_amt
			,vault_ceding_comm_override_after_expenses_amt
			,vault_fronting_fees_amt
			,add_fee_income_due_amt
			,vault_premium_with_profitshare_frontfees_amt
			,risk_group
			,fronting_fee_total_amt
			,underwriting_year_pc
			,@ssk as source_system_sk
			,getdate()
			,getdate()
			,@etl_audit_sk
		FROM 
			edw_temp.tgroup_umbrella_coverage_temp1

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.tgroup_umbrella_coverage_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tgroup_umbrella_coverage_temp1;
		
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