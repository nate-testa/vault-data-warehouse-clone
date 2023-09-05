
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario Valbuena
-- Create Date: 2023-09-01
-- Description: This procedures insert info related to HSB - Cyber
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_hsb_cyber_feed]
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
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tpolicy_hsb_cyber_feed_temp1];
		SELECT 
            getdate() as reporting_date,
            '4004' as company_product_cd,
            'HCP' as product_nm,
            '1004100' as contract_no,
            CASE 
                WHEN CHARINDEX('-', ph.policy_no) > 0 THEN LEFT(ph.policy_no, CHARINDEX('-', ph.policy_no) - 1)
                ELSE ph.policy_no
            END AS policy_no,
            CONVERT(VARCHAR(8), ph.effective_dt, 112) as coverage_effective_dt,
            CONVERT(VARCHAR(8), ph.expiration_dt, 112) as coverage_expiration_dt,
            c.customer_nm as insured_nm,
            c.address_line_1 as dwelling_address,
            c.city_nm as dwelling_city,
            c.state_cd as dwelling_state,
            c.zip_cd as dwelling_zip_cd,
            ROUND(pt.net_premium_amt,0) as hcp_net_premium_amt,
            hac.home_cyber_protection_coverage_deductible as hcp_deductible_amt,
            hc.dwelling_limit_amt as coverage_a_value,
            hac.home_cyber_protection_coverage_limit_amt as slc_limit_amt,
            '' as homeowner_policy_form_no,
            '' as product_form_no,
            '' as client_product_nm,
            '' as dwelling_type,
            '' as base_homeowner_premium,
            ROUND(pt.net_premium_amt,0) as final_homeowner_premium,
            hc.aop_deductible as policy_deductible,
            hc.built_year as year_build,
            hc.total_finished_square_feet as total_living_area,
            '' as no_of_units_in_dwelling,
            '' as email_address,
            '' as home_business,
            CASE 
                WHEN CHARINDEX('-', ph.policy_no) > 0 THEN LEFT(ph.policy_no, CHARINDEX('-', ph.policy_no) - 1)
                ELSE ph.policy_no
            END AS previous_policy_number,
            ss.source_system_nm,
            getdate() as create_ts,
 			getdate() as update_ts,
 		    @etl_audit_sk as etl_audit_sk,
            ph.create_ts as policy_history_create_ts
		INTO [edw_temp].[tpolicy_hsb_cyber_feed_temp1] 
		FROM edw_core.tpolicy_history AS ph
        LEFT JOIN edw_core.tcustomer AS c ON ph.customer_sk = c.customer_sk
        LEFT JOIN edw_core.thome_coverage AS hc ON ph.policy_history_sk = hc.policy_history_sk
        LEFT JOIN edw_core.thome_additional_coverage AS hac ON ph.policy_history_sk = hac.policy_history_sk
        LEFT JOIN edw_core.tpolicy_insured AS pi ON ph.policy_history_sk = pi.policy_history_sk AND ph.transaction_effective_dt = pi.transaction_effective_dt AND pi.primary_insured_in = 'Yes'
        LEFT JOIN edw_core.tpolicy AS p ON ph.policy_sk = p.policy_sk AND ph.effective_dt = p.effective_dt
		LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
        LEFT JOIN edw_core.tsource_system AS ss ON ph.source_system_sk = ss.source_system_sk
        LEFT JOIN (select policy_sk, effective_dt_sk , transaction_seq_no, sum(net_premium_amt) as net_premium_amt 
                    from edw_core.tpolicy_transaction group by policy_sk, effective_dt_sk, transaction_seq_no) AS pt
        ON ph.policy_sk = pt.policy_sk
        AND ph.transaction_seq_no = pt.transaction_seq_no
        WHERE cast(ph.create_ts as datetime2(7)) > @last_source_extract_ts
        ;


		-- Start Insert process
		INSERT INTO [edw_integration].[policy_hsb_cyber_feed](
			reporting_date,
            company_product_cd,
            product_nm,
            contract_no,
            policy_no,
            coverage_effective_dt,
            coverage_expiration_dt,
            insured_nm,
            dwelling_address,
            dwelling_city,
            dwelling_state,
            dwelling_zip_cd,
            hcp_net_premium_amt,
            hcp_deductible_amt,
            coverage_a_value,
            slc_limit_amt,
            homeowner_policy_form_no,
            product_form_no,
            client_product_nm,
            dwelling_type,
            base_homeowner_premium,
            final_homeowner_premium,
            policy_deductible,
            year_build,
            total_living_area,
            no_of_units_in_dwelling,
            email_address,
            home_business,
            previous_policy_number,
            source_system_nm,
            create_ts,
            update_ts,
            etl_audit_sk
		)
		SELECT 
            reporting_date,
            company_product_cd,
            product_nm,
            contract_no,
            policy_no,
            coverage_effective_dt,
            coverage_expiration_dt,
            insured_nm,
            dwelling_address,
            dwelling_city,
            dwelling_state,
            dwelling_zip_cd,
            hcp_net_premium_amt,
            hcp_deductible_amt,
            coverage_a_value,
            slc_limit_amt,
            homeowner_policy_form_no,
            product_form_no,
            client_product_nm,
            dwelling_type,
            base_homeowner_premium,
            final_homeowner_premium,
            policy_deductible,
            year_build,
            total_living_area,
            no_of_units_in_dwelling,
            email_address,
            home_business,
            previous_policy_number,
            source_system_nm,
            create_ts,
            update_ts,
            etl_audit_sk
		FROM [edw_temp].[tpolicy_hsb_cyber_feed_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_history_create_ts) FROM [edw_temp].[tpolicy_hsb_cyber_feed_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tpolicy_hsb_cyber_feed_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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
