-- =============================================
-- Author:		Alberto Almario Valbuena
-- Create Date: 2023-09-05
-- Description: This procedures insert info related to HSB - SLC
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_hsb_slc_feed]
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
		DROP TABLE IF EXISTS [edw_temp].[tpolicy_hsb_slc_feed_temp1];
		SELECT 
            getdate() as reporting_date,
            '4280' as company_product_cd,
            'SLC' as product_nm,
            '1004013' as contract_no,
            CASE 
                WHEN CHARINDEX('-', p.policy_no) > 0 THEN LEFT(p.policy_no, CHARINDEX('-', p.policy_no) - 1)
                ELSE p.policy_no
            END AS policy_no,
            CONVERT(VARCHAR(8), p.effective_dt, 112) as homeowner_policy_effective_dt,
            CONVERT(VARCHAR(8), p.expiration_dt, 112) as homeowner_policy_expiration_dt,
            '' as coverage_effective_dt,
            '' as original_homeowner_policy_effective_dt,
            '' as prior_homeowner_insurance_ind,
            c.customer_nm as insured_nm,
            c.mailing_address_line1 as dwelling_address,
            c.mailing_address_city_nm as dwelling_city,
            c.mailing_address_state_cd as dwelling_state,
            c.mailing_address_zip_cd as dwelling_zip_cd,
            ROUND(pt.ceded_premium_amt,2) as slc_net_premium_amt,
            50000 as slc_limit_amt,
            500 as slc_deductible_amt,
            '' as base_homeowner_premium,
            ROUND(pt.net_premium_amt,2) as final_homeowner_premium,
            hc.aop_deductible as policy_deductible,
            hc.dwelling_limit_amt as coverage_a_value,
            hc.other_structures_limit_amt as coverage_b_value,
            hc.contents_limit_amt as coverage_c_value,
            '' as homeowner_policy_form_no,
            '' as homeowners_or_dwelling_fire_policy_form_type,
            '' as product_form_no,
            '' as client_product_nm,
            hc.residence_type,
            '' as usage_type,
            hc.occupancy_type as occupancy,
            hc.built_year as year_build,
            hc.total_finished_square_feet as total_living_area,
            '' as no_of_units_in_dwelling,
            hc.hvac_updated_year as heating_system_updated_yr,
            hc.electrical_updated_year as electrical_system_updated_yr,
            hc.plumbing_updated_year as plumbing_system_updated_yr,
            '' as distance_to_hydrant,
            '' as pricing_tier,
            '' as insurance_score,
            '' as rating_territory_cd,
            '' as protection_class_cd,
            CASE 
                WHEN CHARINDEX('-', p.policy_no) > 0 THEN LEFT(p.policy_no, CHARINDEX('-', p.policy_no) - 1)
                ELSE p.policy_no
            END AS previous_policy_number,
            c.agency_id as agent_code,
            '' as branch_code,
            ss.source_system_nm,
            getdate() as create_ts,
 			getdate() as update_ts,
 		    @etl_audit_sk as etl_audit_sk,
            p.create_ts as policy_history_create_ts
		INTO [edw_temp].[tpolicy_hsb_slc_feed_temp1] 
        FROM 
            edw_core.tpolicy AS p
        INNER JOIN 
            edw_core.tdate AS d ON d.actual_dt = p.effective_dt
        LEFT JOIN 
            edw_core.tcustomer AS c ON c.customer_id = p.customer_id
        LEFT JOIN 
            edw_core.tproduct AS pr ON pr.product_cd = p.product_cd
        LEFT JOIN 
            (
                select 
                    policy_no, effective_dt, transaction_seq_no, aop_deductible, dwelling_limit_amt, other_structures_limit_amt, contents_limit_amt, residence_type, 
                    occupancy_type, built_year, total_finished_square_feet, hvac_updated_year, electrical_updated_year, plumbing_updated_year,
                    ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY transaction_seq_no DESC) AS RN
                from edw_core.thome_coverage 
            ) AS hc 
            ON hc.policy_no = p.policy_no 
            AND hc.effective_dt = p.effective_dt
            AND hc.RN = 1
        LEFT JOIN 
            (
                select 
                    policy_no, effective_dt, transaction_seq_no, home_systems_protection_limit_amt,
                    ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY transaction_seq_no DESC) AS RN
                from edw_core.thome_additional_coverage
            ) AS hac
            ON hac.policy_no = p.policy_no 
            AND hac.effective_dt = p.effective_dt
            AND hac.RN = 1
        LEFT JOIN 
            edw_core.tsource_system AS ss ON ss.source_system_sk = p.source_system_sk
        LEFT JOIN
            (
                select 
                    pt.policy_sk, d.actual_dt as effective_dt, SUM(pt.net_premium_amt) as net_premium_amt, SUM(pt.ceded_premium_amt) as ceded_premium_amt
                from edw_core.tpolicy_transaction as pt
                inner join edw_core.tdate d on pt.effective_dt_sk = d.date_sk
                group by pt.policy_sk, d.actual_dt
            ) AS pt 
            ON pt.policy_sk = p.policy_sk 
            AND pt.effective_dt = p.effective_dt
        WHERE cast(p.create_ts as datetime2(7)) > @last_source_extract_ts
        ;


		-- Start Insert process
		INSERT INTO [edw_integration].[policy_hsb_slc_feed](
            reporting_date,
            company_product_cd,
            product_nm,
            contract_no,
            policy_no,
            homeowner_policy_effective_dt,
            homeowner_policy_expiration_dt,
            coverage_effective_dt,
            original_homeowner_policy_effective_dt,
            prior_homeowner_insurance_ind,
            insured_nm,
            dwelling_address,
            dwelling_city,
            dwelling_state,
            dwelling_zip_cd,
            slc_net_premium_amt,
            slc_limit_amt,
            slc_deductible_amt,
            base_homeowner_premium,
            final_homeowner_premium,
            policy_deductible,
            coverage_a_value,
            coverage_b_value,
            coverage_c_value,
            homeowner_policy_form_no,
            homeowners_or_dwelling_fire_policy_form_type,
            product_form_no,
            client_product_nm,
            residence_type,
            usage_type,
            occupancy,
            year_build,
            total_living_area,
            no_of_units_in_dwelling,
            heating_system_updated_yr,
            electrical_system_updated_yr,
            plumbing_system_updated_yr,
            distance_to_hydrant,
            pricing_tier,
            insurance_score,
            rating_territory_cd,
            protection_class_cd,
            previous_policy_number,
            agent_code,
            branch_code,
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
            homeowner_policy_effective_dt,
            homeowner_policy_expiration_dt,
            coverage_effective_dt,
            original_homeowner_policy_effective_dt,
            prior_homeowner_insurance_ind,
            insured_nm,
            dwelling_address,
            dwelling_city,
            dwelling_state,
            dwelling_zip_cd,
            slc_net_premium_amt,
            slc_limit_amt,
            slc_deductible_amt,
            base_homeowner_premium,
            final_homeowner_premium,
            policy_deductible,
            coverage_a_value,
            coverage_b_value,
            coverage_c_value,
            homeowner_policy_form_no,
            homeowners_or_dwelling_fire_policy_form_type,
            product_form_no,
            client_product_nm,
            residence_type,
            usage_type,
            occupancy,
            year_build,
            total_living_area,
            no_of_units_in_dwelling,
            heating_system_updated_yr,
            electrical_system_updated_yr,
            plumbing_system_updated_yr,
            distance_to_hydrant,
            pricing_tier,
            insurance_score,
            rating_territory_cd,
            protection_class_cd,
            previous_policy_number,
            agent_code,
            branch_code,
            source_system_nm,
            create_ts,
            update_ts,
            etl_audit_sk
		FROM [edw_temp].[tpolicy_hsb_slc_feed_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_history_create_ts) FROM [edw_temp].[tpolicy_hsb_slc_feed_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tpolicy_hsb_slc_feed_temp1];
		
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

