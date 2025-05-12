-- =============================================
-- Author:		Alberto Almario Valbuena
-- Create Date: 2023-09-01
-- Description: This procedures insert info related to HSB - Cyber
-- =============================================
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 03/06/2025		Alberto Almario				1. Change logic to extract last_source_extract_ts value
-- 03/06/2025       Sandeep Gundreddy           2. Added logic to exclude trasactions processed and effective in future months
-- ========================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_hsb_cyber_feed]
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
		SELECT @last_source_extract_ts = CASE 
                                            WHEN edw_core.fn_get_last_source_extract_ts(@process_nm) < '2020-01-01 00:00:00' THEN '2025-01-31 00:00:00'
                                            ELSE edw_core.fn_get_last_source_extract_ts(@process_nm)
                                         END;
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

        -----------------------------------------------------
        -- CREATE CURSOR TO ITERATE EVERY MONTH TO PROCESS --
        -----------------------------------------------------
        -- Drop tmp table
        DROP TABLE IF EXISTS #LastDaysOfMonthTmpTbl;

        -- Calculate the last day of the month for the date in control table
        DECLARE @LastDayOfMonth date;
        SET @LastDayOfMonth = EOMONTH(@last_source_extract_ts);

        -- Define a recursive CTE to generate the last days of each month
        WITH LastDaysOfMonthCTE AS (
            SELECT @LastDayOfMonth AS LastDayOfMonth
            UNION ALL
            SELECT EOMONTH(DATEADD(month, 1, LastDayOfMonth))
            FROM LastDaysOfMonthCTE
            WHERE LastDayOfMonth < EOMONTH(GETDATE())
        )

        -- Create tmp table for last day of months
        SELECT * INTO #LastDaysOfMonthTmpTbl 
        FROM LastDaysOfMonthCTE OPTION (MAXRECURSION 200);-- Allow a maximum of 200 recursions for the CTE.

        DECLARE @CurrentLastDayOfMonth DATE;

        -- Declare the cursor
        DECLARE LastDaysCursor CURSOR FOR
        SELECT LastDayOfMonth FROM #LastDaysOfMonthTmpTbl ORDER BY LastDayOfMonth ASC;

        --Drop and Create the temp2 table. This will store the last reporting_date and row_count for every iteration in the cursor.
        DROP TABLE IF EXISTS [edw_temp].[policy_hsb_cyber_feed_temp2];
        SELECT * INTO [edw_temp].[policy_hsb_cyber_feed_temp2] FROM (SELECT @last_source_extract_ts AS reporting_date, 0 AS row_count) AS t;

        -- Open the cursor
        OPEN LastDaysCursor;
        FETCH NEXT FROM LastDaysCursor INTO @CurrentLastDayOfMonth;
        WHILE @@FETCH_STATUS = 0
        BEGIN

            -- Step1 limit amount of rows.
            DROP TABLE IF EXISTS [edw_temp].[policy_hsb_cyber_feed_temp1];
            SELECT 
                p.inforce_dt as reporting_date,
                CASE 
                    WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '4404'
                    WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '4854'
                END as company_product_cd,
                'HCP' as product_nm,
                CASE 
                    WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '1004100'
                    WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '1004610'
                END AS contract_no,
                CASE 
                    WHEN CHARINDEX('-', p.policy_no) > 0 THEN LEFT(p.policy_no, CHARINDEX('-', p.policy_no) - 1)
                    ELSE p.policy_no
                END AS policy_no,
                CONVERT(VARCHAR(8), pt.transaction_effective_dt, 112) as coverage_effective_dt,
                CONVERT(VARCHAR(8), p.expiration_dt, 112) as coverage_expiration_dt,
                p.insured_nm,
                hl.address_line_1 as dwelling_address,
                hl.city_nm as dwelling_city,
                hl.state_cd as dwelling_state,
                hl.zip_cd as dwelling_zip_cd,
                ROUND(pt.ceded_premium_amt,2) as hcp_net_premium_amt,
                CASE 
                    WHEN hac.home_cyber_protection_coverage_deductible IN ('','0') OR hac.home_cyber_protection_coverage_deductible IS NULL THEN '500'
                    ELSE hac.home_cyber_protection_coverage_deductible
                END AS hcp_deductible_amt,
                hc.dwelling_limit_amt as coverage_a_value,
                REPLACE(hac.home_cyber_protection_coverage_limit_amt,',','') as hcp_limit_amt,
                '' as homeowner_policy_form_no,
                '' as product_form_no,
                '' as client_product_nm,
                CASE 
                    WHEN p.product_cd = 'HO' THEN 280
                    WHEN p.product_cd = 'CO' THEN 282
                END AS dwelling_type,
                '' as base_homeowner_premium,
                ROUND(p.annual_premium_amt,2) as final_homeowner_premium,
                CASE 
                    WHEN REPLACE(hac.home_cyber_protection_coverage_limit_amt,',','') IN ('','0','25000','50000','100000') OR hac.home_cyber_protection_coverage_limit_amt IS NULL THEN '500'
                    WHEN REPLACE(hac.home_cyber_protection_coverage_limit_amt,',','') IN ('250000','500000') THEN '1000'
                END as policy_deductible,
                hc.built_year as year_build,
                hc.total_finished_square_feet as total_living_area,
                '' as no_of_units_in_dwelling,
                '' as email_address,
                '' as home_business,
                CASE 
                    WHEN CHARINDEX('-', p.policy_no) > 0 THEN LEFT(p.policy_no, CHARINDEX('-', p.policy_no) - 1)
                    ELSE p.policy_no
                END AS previous_policy_number,
                ss.source_system_nm,
                getdate() as create_ts,
                getdate() as update_ts,
                @etl_audit_sk as etl_audit_sk
            INTO [edw_temp].[policy_hsb_cyber_feed_temp1] 
            FROM 
                (
                    select p.*, d.actual_dt as inforce_dt, i.annual_premium_amt
                    from edw_core.tdaily_inforce_policy as i
                    inner join edw_core.tpolicy as p ON i.policy_sk = p.policy_sk
                    inner join edw_core.tdate as d ON i.inforce_dt_sk = d.date_sk
                    where p.product_cd in ('HO','CO')
                    and d.actual_dt = @CurrentLastDayOfMonth
                ) AS p
            INNER JOIN
                (
                    select 
                        pt.policy_sk, d.actual_dt as effective_dt, SUM(pt.net_premium_amt) as net_premium_amt, SUM(pt.ceded_annual_premium_amt) as ceded_premium_amt, Min(d2.actual_dt) as transaction_effective_dt
                    from edw_core.tpolicy_transaction as pt
                    inner join edw_core.tdate d on pt.effective_dt_sk = d.date_sk
                    inner join edw_core.tdate d2 on pt.transaction_effective_dt_sk = d2.date_sk
                    inner join edw_core.tdate d3 on pt.transaction_dt_sk=d3.date_sk
                    inner join edw_core.tinternal_coverage as ic on pt.internal_coverage_sk = ic.internal_coverage_sk and d2.actual_dt<=@CurrentLastDayOfMonth and d3.actual_dt<=@CurrentLastDayOfMonth
                    where ic.internal_coverage_cd = 'Cyber Protection'
                    group by pt.policy_sk, d.actual_dt
                ) AS pt 
                ON pt.policy_sk = p.policy_sk 
            LEFT JOIN 
                edw_core.thome_location AS hl 
                ON p.policy_no = hl.policy_no
                AND p.effective_dt = hl.effective_dt
            LEFT JOIN 
                edw_core.tproduct AS pr ON pr.product_cd = p.product_cd
            LEFT JOIN 
                (
                    select 
                        policy_no, effective_dt, transaction_seq_no, 
                        CASE 
                            WHEN ISNUMERIC(aop_deductible) = 0 THEN NULL 
                            ELSE ROUND(aop_deductible,0,1)
                        END AS aop_deductible, 
                        dwelling_limit_amt, other_structures_limit_amt, contents_limit_amt, residence_type, 
                        occupancy_type, built_year, total_finished_square_feet, hvac_updated_year, electrical_updated_year, plumbing_updated_year,
                        ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY transaction_seq_no DESC) AS RN
                    from edw_core.thome_coverage where transaction_effective_dt<=@CurrentLastDayOfMonth and transaction_dt<=@CurrentLastDayOfMonth
                ) AS hc 
                ON hc.policy_no = p.policy_no 
                AND hc.effective_dt = p.effective_dt
                AND hc.RN = 1
            LEFT JOIN 
                (
                    select 
                        policy_no, effective_dt, transaction_seq_no, home_systems_protection_limit_amt, home_cyber_protection_coverage_deductible, home_cyber_protection_coverage_limit_amt, home_cyber_protection_coverage_in,
                        ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY transaction_seq_no DESC) AS RN
                    from edw_core.thome_additional_coverage where transaction_effective_dt<=@CurrentLastDayOfMonth and transaction_dt<=@CurrentLastDayOfMonth
                ) AS hac
                ON hac.policy_no = p.policy_no 
                AND hac.effective_dt = p.effective_dt
                AND hac.RN = 1
            LEFT JOIN 
                edw_core.tsource_system AS ss ON ss.source_system_sk = p.source_system_sk
            WHERE hac.home_cyber_protection_coverage_in = 'Yes'
            ;

            -- Delete previous data for the date that we are processing
            DELETE FROM [edw_integration].[policy_hsb_cyber_feed] WHERE reporting_date = @CurrentLastDayOfMonth

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
                hcp_limit_amt,
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
                hcp_limit_amt,
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
            FROM [edw_temp].[policy_hsb_cyber_feed_temp1];

            --Insert max_date and row_count
            INSERT INTO [edw_temp].[policy_hsb_cyber_feed_temp2]
            SELECT MAX(reporting_date) AS reporting_date, COUNT(1) AS row_count  FROM [edw_temp].[policy_hsb_cyber_feed_temp1]
            ;        

            FETCH NEXT FROM LastDaysCursor INTO @CurrentLastDayOfMonth;
            
        END

        -- Close and deallocate the cursor
        CLOSE LastDaysCursor;
        DEALLOCATE LastDaysCursor;

        ----------------------------------------------------
        -- CLOSE CURSOR TO ITERATE EVERY MONTH TO PROCESS --
        ----------------------------------------------------

        SET @rows_affected = (SELECT SUM(row_count) AS row_count FROM [edw_temp].[policy_hsb_cyber_feed_temp2]);

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t2.reporting_date) FROM [edw_temp].[policy_hsb_cyber_feed_temp2] t2),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[policy_hsb_cyber_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_hsb_cyber_feed_temp2];
		
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
