SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==============================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2023-10-17
-- Description: This stored procedure insert and update info related to policy_ivans_pel_feed.
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date      |Author						|Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------
-- 04/05/2024       Sandeep Gundreddy           Repush to Git Repo
-- 04/05/2024       Sandeep Gundreddy           Repush to Git Repo
-- 21/07/2025       Alberto Almario             Add filter location_deleted_in = 'No'
-- ==============================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_ivans_pel_feed]
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

		--************Start************

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_pel_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_pel_feed_temp2];

        SELECT 
            pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, p.customer_id, pt.policy_transaction_type_sk, pt.source_system_sk, p.policy_no, p.effective_dt,
            MAX(ph.transaction_ts) as transaction_ts, 
            SUM(pt.premium_amt) as premium_amt,
            --SUM(pt.annual_premium_amt) as annual_premium_amt
            CASE WHEN pt.policy_transaction_type_sk = 5
				THEN
        			(SELECT SUM(subpt.premium_amt)
        			    FROM edw_core.tpolicy_transaction subpt
        			    WHERE subpt.policy_sk = pt.policy_sk
        			    AND subpt.transaction_seq_no <= pt.transaction_seq_no)
    			ELSE
    			    (SELECT SUM(subpt.annual_premium_amt)
    			        FROM edw_core.tpolicy_transaction subpt
    			        WHERE subpt.policy_sk = pt.policy_sk
    			        AND subpt.transaction_seq_no <= pt.transaction_seq_no)
    		END AS annual_premium_amt
        INTO [edw_temp].[policy_ivans_pel_feed_temp2]
        FROM edw_core.tpolicy_transaction as pt
        INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
        INNER JOIN edw_core.tpolicy as p ON pt.policy_sk = p.policy_sk
        INNER JOIN edw_core.tpolicy_history as ph 
        ON pt.policy_sk = ph.policy_sk
        AND pt.transaction_seq_no = ph.transaction_seq_no
        WHERE 1=1
            AND pr.product_cd = 'PEL'
            AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
        GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, p.customer_id, pt.policy_transaction_type_sk, pt.source_system_sk, p.policy_no, p.effective_dt
        ;

        WITH 
        loss_history AS (
            SELECT 
                policy_no, effective_dt, transaction_seq_no, max(loss_seq_no) as loss_seq_no 
            FROM 
                edw_core.tloss_history
            GROUP BY 
                policy_no, effective_dt, transaction_seq_no
        ),
        original_policy AS (
            SELECT original_policy_no, min(effective_dt) as min_effective_dt, min(expiration_dt) as min_expiration_dt 
                FROM edw_core.tpolicy 
            GROUP BY original_policy_no                
        ),
        json_pel_locations AS (
            SELECT 
                plf.policy_no, plf.effective_dt, plf.transaction_seq_no,
                (
                    SELECT
                        CONCAT('L',pl.location_no) as locationNumber,
                        'Location' as addressTypeCd,
                        ph.customer_id as insurerId,
                        pl.address_line_1 as addr1,
                        pl.city_nm as city,
                        e.state_nm as stateProv,
                        pl.state_cd as stateProvCd,
                        pl.zip_cd as postalCode,
                        pl.county_nm as county,
                        pl.country_nm as country
                    FROM edw_core.tpel_location as pl
                    INNER JOIN edw_core.tpolicy_history as ph ON pl.policy_history_sk = ph.policy_history_sk
                    INNER JOIN edw_core.tstate as e ON pl.state_cd = e.state_cd
                    WHERE pl.policy_no = plf.policy_no
                    AND pl.effective_dt = plf.effective_dt
                    AND pl.transaction_seq_no = plf.transaction_seq_no
                    AND pl.location_deleted_in = 'No'
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Locations
            FROM edw_core.tpel_location AS plf
            GROUP BY plf.policy_no, plf.effective_dt, plf.transaction_seq_no
        ),
        json_pel_coverages AS (
            SELECT ptf.policy_no, ptf.effective_dt ,ptf.transaction_seq_no,
                (
                    SELECT * FROM (
                        SELECT  
                            ic.internal_coverage_cd AS coverageCd,
                            CASE 
                                WHEN ic.internal_coverage_cd = 'DNO Coverage'       THEN 'Not for Profit Directors and Officers Coverage' 
                                WHEN ic.internal_coverage_cd = 'UM Liability'       THEN 'Uninsured / Underinsured Liability Coverage' 
                                WHEN ic.internal_coverage_cd = 'UM Motorist'        THEN 'Uninsured / Underinsured Motorist Coverage' 
                                WHEN ic.internal_coverage_cd = 'EPL Coverage'       THEN 'Employment Practices Liability Coverage' 
                                WHEN ic.internal_coverage_cd = 'Excess Liability'   THEN 'Excess Liability Coverage' 
                            END AS coverageDesc,
                            CASE
                                WHEN ic.internal_coverage_cd = 'DNO Coverage'       THEN pc.do_limit_amt 
                                WHEN ic.internal_coverage_cd = 'UM Liability'       THEN pc.uninsured_underinsured_liability_amt 
                                WHEN ic.internal_coverage_cd = 'UM Motorist'        THEN pc.uninsured_underinsured_motorist_liability_amt 
                                WHEN ic.internal_coverage_cd = 'EPL Coverage'       THEN pc.employment_practices_liability_amt 
                                WHEN ic.internal_coverage_cd = 'Excess Liability'   THEN cast(pc.pel_limit_amt as varchar(255)) 
                            END AS limits,
                            '' AS deductibles, 
                            pt.annual_premium_amt AS currentTermAmt,
                            pt.premium_amt AS netChangeAmt,
                            '' AS optionTypeCd,
                            NULL AS optionValue
                        FROM 
                            (
                                SELECT 
                                    pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk,
                                    (
                                        SELECT SUM(subpt.annual_premium_amt)
                                        FROM edw_core.tpolicy_transaction subpt 
                                        WHERE subpt.policy_sk = pt.policy_sk
                                        AND subpt.effective_dt_sk = pt.effective_dt_sk
                                        AND subpt.internal_coverage_sk = pt.internal_coverage_sk
                                        AND subpt.transaction_seq_no <= pt.transaction_seq_no
                                    ) as annual_premium_amt,
                                    SUM(pt.premium_amt) AS premium_amt 
                                FROM edw_core.tpolicy_transaction as pt
                                INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
                                INNER JOIN edw_core.tpolicy_history as ph 
                                ON pt.policy_sk = ph.policy_sk
                                AND pt.transaction_seq_no = ph.transaction_seq_no
                                WHERE 1=1
                                    AND pr.product_cd = 'PEL'
                                AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
                                GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk
                            ) as pt 
                            INNER JOIN edw_core.tpel_coverage as pc ON pt.coverage_sk = pc.pel_coverage_sk
                            INNER JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
                        WHERE  1=1
                            AND pt.policy_sk = ptf.policy_sk
                            AND pt.effective_dt_sk = ptf.effective_dt_sk
                            AND pt.transaction_seq_no = ptf.transaction_seq_no
                        UNION ALL
                        SELECT 
                            'AUTO' AS coverageCd,
                            'Number of Autos' AS coverageDesc,
                            '' AS limits,
                            '' AS deductibles,
                            NULL AS currentTermAmt,
                            NULL AS netChangeAmt,
                            MAX(vehicle_no) AS optionTypeCd,
                            MAX(vehicle_no) AS optionValue
                        FROM edw_core.tpel_vehicle AS pv
                        WHERE  1=1
                            AND pv.policy_no = ptf.policy_no
                            AND pv.effective_dt = ptf.effective_dt
                            AND pv.transaction_seq_no = ptf.transaction_seq_no
                        GROUP BY pv.policy_no, pv.effective_dt, pv.transaction_seq_no
                    ) AS coverages
                    FOR JSON PATH
                ) AS PEL_Coverages
            FROM [edw_temp].[policy_ivans_pel_feed_temp2] as ptf
        ),
        json_pel_drivers AS (
            SELECT 
                pdf.policy_no, pdf.effective_dt, pdf.transaction_seq_no,
                (
                    SELECT
                        pd.driver_no as id,
                        ph.customer_id as insuredId,
                        pd.first_nm as firstName,
                        pd.middle_nm as middleName,
                        pd.last_nm as lastName,
                        pd.birth_dt as driverDob,
                        pd.license_status as licenseStatus,
                        pd.license_country_nm as licenseCountryOfIssue,
                        pd.license_state_cd as licenseState,
                        pd.license_year as licenseYear,
                        pd.license_no as licenseNumber
                    FROM edw_core.tpel_driver as pd
                    INNER JOIN edw_core.tpolicy_history as ph ON pd.policy_history_sk = ph.policy_history_sk
                    WHERE pd.policy_no = pdf.policy_no
                    AND pd.effective_dt = pdf.effective_dt
                    AND pd.transaction_seq_no = pdf.transaction_seq_no
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Drivers
            FROM edw_core.tpel_driver AS pdf
            GROUP BY pdf.policy_no, pdf.effective_dt, pdf.transaction_seq_no
        ),
        json_pel_objects AS (
            SELECT 
                phf.policy_no, phf.effective_dt, phf.transaction_seq_no,
                (
                    SELECT
                        pv.vehicle_no as id,
                        ph.customer_id as insuredId,
                        pv.vehicle_type as vehicleType,
                        pv.vehicle_vin as vin,
                        pv.vehicle_year as modelyear,
                        pv.vehicle_make as manufacturer,
                        pv.vehicle_model as model  
                    FROM edw_core.tpel_vehicle as pv
                    INNER JOIN edw_core.tpolicy_history as ph ON pv.policy_history_sk = ph.policy_history_sk
                    WHERE pv.policy_no = phf.policy_no
                    AND pv.effective_dt = phf.effective_dt
                    AND pv.transaction_seq_no = phf.transaction_seq_no
                    AND pv.vehicle_deleted_in = 'No'
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Vehicles,
                (
                    SELECT
                        pw.watercraft_no as id,
                        ph.customer_id as insuredId,
                        pw.watercraft_year as yearbuilt,
                        pw.watercraft_make as manufacturer,
                        pw.watercraft_model as model,
                        REPLACE(REPLACE(pw.watercraft_length,'<','less than'),'>','greater than') as [length],
                        REPLACE(REPLACE(pw.watercraft_horsepower,'<','less than'),'>','greater than') as horsepower
                    FROM edw_core.tpel_watercraft as pw
                    INNER JOIN edw_core.tpolicy_history as ph ON pw.policy_history_sk = ph.policy_history_sk
                    WHERE pw.policy_no = phf.policy_no
                    AND pw.effective_dt = phf.effective_dt
                    AND pw.transaction_seq_no = phf.transaction_seq_no
                    AND pw.watercraft_deleted_in = 'No'
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Watercrafts
            FROM edw_core.tpolicy_history AS phf
            GROUP BY phf.policy_no, phf.effective_dt, phf.transaction_seq_no
        ),
        json_pel_prior_or_underly AS (
            SELECT 
                ptf.policy_no, ptf.effective_dt, ptf.transaction_seq_no,
                (
                    SELECT 
                        p.prior_policy_no as policyNumber, 
                        ppd.insured_nm as insurerName, 
                        ppr.product_nm as lobCd, 
                        ppd.effective_dt as effectiveDate, 
                        ppd.expiration_dt as expirationDate, 
                        DATEDIFF(MONTH, ppd.effective_dt, ppd.expiration_dt) AS numUnits
                    FROM
                        (
                            SELECT 
                                a.base_policy_no,
                                a.policy_sk, 
                                a.policy_no,
                                a.policy_seq, 
                                a.effective_dt, 
                                a.transaction_seq_no,
                                CASE
                                    WHEN a.policy_seq = 0 THEN NULL
                                    WHEN a.policy_seq = 1 THEN base_policy_no
                                    ELSE a.base_policy_no + '-' + RIGHT('00' + CAST(a.policy_seq - 1 AS VARCHAR), 2)
                                END AS prior_policy_no
                            FROM 
                                (
                                    SELECT
                                        policy_sk, policy_no,
                                        LEFT(policy_no, CASE WHEN CHARINDEX('-', policy_no) > 0 THEN CHARINDEX('-', policy_no) - 1 ELSE LEN(policy_no) END) AS base_policy_no,
                                        CAST(CASE WHEN CHARINDEX('-', policy_no) > 0 THEN RIGHT(policy_no, LEN(policy_no) - CHARINDEX('-', policy_no)) ELSE 0 END AS INT) AS policy_seq,
                                        effective_dt, transaction_seq_no
                                    FROM [edw_temp].[policy_ivans_pel_feed_temp2]
                                ) AS a
                            WHERE a.policy_seq > 0 --Filter policy that has prior policy
                        ) as p
                    INNER JOIN edw_core.tpolicy AS ppd
                    ON p.prior_policy_no = ppd.policy_no
                    INNER JOIN edw_core.tproduct AS ppr
                    ON ppd.product_cd = ppr.product_cd
                    WHERE p.policy_no = ptf.policy_no
                    AND p.effective_dt = ptf.effective_dt
                    AND p.transaction_seq_no = ptf.transaction_seq_no
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Prior_Policies,
                (
                    SELECT 
                        p.policy_no as policyNumber, 
                        p.insured_nm as insurerName,
                        'AUTO' as lobCd,
                        p.effective_dt as effectiveDate, 
                        p.expiration_dt as expirationDate, 
                        DATEDIFF(MONTH, p.effective_dt, p.expiration_dt) AS numUnits
                    FROM edw_core.tpolicy as p
                    WHERE product_cd = 'AU'
                    AND p.customer_id = ptf.customer_id
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS PEL_Underly_Policies
            FROM [edw_temp].[policy_ivans_pel_feed_temp2] AS ptf
        )


		SELECT 
            'PolicyDownload' as [MsgTypeCd_001],
            CASE 
                WHEN ptt.policy_transaction_type_nm = 'New' THEN 'NBS'
                WHEN ptt.policy_transaction_type_nm = 'Endorsement' THEN 'PCH'
                WHEN ptt.policy_transaction_type_nm = 'Cancellation' THEN 'XLC'
                WHEN ptt.policy_transaction_type_nm = 'Reinstatement' THEN 'REI'
                WHEN ptt.policy_transaction_type_nm = 'Renewal' THEN 'RW'
                ELSE 'OTH'
            END as [BusinessPurposeTypeCd_002],
            getdate() as [ActivityDt_003],
            d1.actual_dt as [TransactionEffectiveDt_004],
            '2.0' as [IVANSXMLVersionCd_005],
            'USD' as [CurCd_006],
            'P' as [BroadLOBCd_007],
            'EDW' as [SourceSystem_008],
            p.broker_id as [ContractNumber_009],
            '' as [ProducerSubCode_010],
            pi.insured_nm as [InsurerId_011],
            pi.last_nm as [Surname_012],
            COALESCE(pi.first_nm, c.customer_nm) as [GivenName_013],
            '' as [OtherGivenName_014],
            pi.prefix as [Prefix_015],
            CASE
                WHEN pi.mailing_address_line_1 is not null THEN 'MailingAddress' 
                ELSE 'LocationAddress'
            END as [AddrTypeCd_016],
            CASE
                WHEN pi.mailing_address_line_1 IS NOT NULL 
                    THEN CONCAT(pi.mailing_address_line_1, CASE WHEN pi.mailing_address_line_2 IS NOT NULL THEN pi.mailing_address_line_2 END) 
                ELSE pi.mailing_address_line_1
            END as [Addr1_017],
            pi.mailing_address_city_nm as [City_018],
            pi.mailing_address_state_cd as [StateProvCd_019],
            pi.mailing_address_state_cd as [StateProv_020],
            pi.mailing_address_zip_cd as [PostalCode_021],
            pi.mailing_address_country_nm as [Country_022],
            pi.mailing_address_county_nm as [County_023],
            '' as [PhoneTypeCd_024],
            RIGHT(REPLACE(TRANSLATE(pi.home_phone_no, '+-/()#', '      '), ' ', ''), 10) as [HomePhoneNumber_025],
		    RIGHT(REPLACE(TRANSLATE(pi.mobile_phone_no, '+-/()#', '      '), ' ', ''), 10) as [MobilePhoneNumber_025],
            pi.email as [EmailAddr_026],
            '' as [GenderCd_027],
            '' as [MaritalStatusCd_028],
            pi.birth_dt as [BirthDt_029],
            c.occupation_desc as [OccupationDesc_030],
            CASE WHEN pi.primary_insured_in in ('Yes', 'No') THEN 'IN' ELSE '' END AS [InsuredOrPrincipalRoleCd_031],
            CASE WHEN pi.primary_insured_in in ('Yes', 'No') THEN 'Insured' ELSE '' END as [InsuredOrPrincipalRoleDesc_032],
            p.policy_no as [PolicyNumber_033],
            '' as [BillingAccountNumber_034],
            'P' as [BroadLOBCd_035],
            pr.product_nm as [LOBCd_036],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_037],
            p.effective_dt as [EffectiveDt_038],
            p.expiration_dt as [ExpirationDt_039],
            DATEDIFF(MONTH,p.effective_dt, p.expiration_dt) as [NumUnits_040],
            P.policy_term as [Description_041],
            '' as [ControllingStateProvCd_042],
            CASE WHEN ba.bill_type in ('Insured', 'Mortgagee') THEN 'Direct' ELSE 'Not Direct' END AS [BillingMethodCd_043],
            COALESCE(pt.annual_premium_amt, 0) as [Amt_044],
            COALESCE(pt.premium_amt, 0) as [Amt_045],
            op.min_effective_dt as [OriginalPolicyInceptionDt_046],
            '' as [PayorCd_047],
            '' as [RenewalBillingMethodCd_048],
            '' as [RenewalPayorCd_049],
            '' as [Dummy_050],
            '' as [Dummy_051],
            '' as [Dummy_052],
            '' as [Dummy_053],
            '' as [Dummy_054],
            '' as [Dummy_055],
            '' as [Dummy_056],
            '' as [CoverageCd_057],
            '' as [FormatInteger_058],
            '' as [MethodPaymentCd_059],
            CASE 
                WHEN ba.payment_plan = '1P' THEN 'Full Pay'
                ELSE replace(ba.payment_plan, 'P', ' Pay')
            END as [PaymentPlanCd_060],
            '' as [Dummy_061],
            '' as [Dummy_062],
            '' as [Dummy_063],
            '' as [Dummy_064],
            '' as [Dummy_065],
            '' as [Dummy_066],
            '' as [Dummy_067],
            '' as [Dummy_068],
            '' as [Dummy_069],
            '' as [Dummy_070],
            '' as [Dummy_071],
            '' as [Dummy_072],
            p.product_cd as [LOBCd_073],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_074],
            '' as [LocationRef_075],
            'PersUmbrella' as [RiskType_076],
            pi.insured_type as [CommercialName_077],
            jpl.PEL_Locations,
            jpc.PEL_Coverages,
            jpd.PEL_Drivers,
            CASE 
                WHEN jpo.PEL_Vehicles IS NOT NULL AND jpo.PEL_Watercrafts IS NOT NULL
                    THEN JSON_QUERY('[{"Vehicle":' + jpo.PEL_Vehicles + ',"Watercraft":' + jpo.PEL_Watercrafts + '}]')
                WHEN jpo.PEL_Vehicles IS NOT NULL AND jpo.PEL_Watercrafts IS NULL 
                    THEN JSON_QUERY('[{"Vehicle":' + jpo.PEL_Vehicles + '}]')
                WHEN jpo.PEL_Vehicles IS NULL AND jpo.PEL_Watercrafts IS NOT NULL 
                    THEN JSON_QUERY('[{"Watercraft":' + jpo.PEL_Watercrafts + '}]')
            ELSE NULL END AS [PEL_Objects],
            CASE 
                WHEN jppu.PEL_Prior_Policies IS NOT NULL AND jppu.PEL_Underly_Policies IS NOT NULL
                    THEN JSON_QUERY('[{"Prior":' + jppu.PEL_Prior_Policies + ',"Underly":' + jppu.PEL_Underly_Policies + '}]')
                WHEN jppu.PEL_Prior_Policies IS NOT NULL AND jppu.PEL_Underly_Policies IS NULL 
                    THEN JSON_QUERY('[{"Prior":' + jppu.PEL_Prior_Policies + '}]')
                WHEN jppu.PEL_Prior_Policies IS NULL AND jppu.PEL_Underly_Policies IS NOT NULL 
                    THEN JSON_QUERY('[{"Underly":' + jppu.PEL_Underly_Policies + '}]')
            ELSE NULL END AS [PEL_Prior_or_Underly],
            pt.transaction_seq_no,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk,
            tprc.national_producer_no as [NIPRid_200],
            pt.transaction_ts as policy_history_transaction_ts
        INTO [edw_temp].[policy_ivans_pel_feed_temp1] 
        FROM [edw_temp].[policy_ivans_pel_feed_temp2] AS pt
		INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
        INNER JOIN edw_core.tbroker AS b ON p.broker_id = b.broker_id
        LEFT JOIN edw_core.tpolicy_insured as pi ON p.policy_no = pi.policy_no AND p.effective_dt = pi.effective_dt AND pt.transaction_seq_no = pi.transaction_seq_no AND pi.primary_insured_in = 'Yes'
		LEFT JOIN edw_core.tdate AS d1 ON pt.transaction_effective_dt_sk = d1.date_sk
        LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_dt_sk = d2.date_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
		LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_transaction_type AS ptt ON pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
        LEFT JOIN edw_core.tbillingaccount AS ba ON p.billingaccount_sk = ba.billingaccount_sk
        LEFT JOIN loss_history AS lh ON p.policy_no = lh.policy_no AND p.effective_dt = lh.effective_dt AND pt.transaction_seq_no = lh.transaction_seq_no
        LEFT JOIN original_policy AS op ON p.original_policy_no = op.original_policy_no
        LEFT JOIN json_pel_locations AS jpl
            ON p.policy_no = jpl.policy_no AND p.effective_dt = jpl.effective_dt AND pt.transaction_seq_no = jpl.transaction_seq_no
        LEFT JOIN json_pel_coverages AS jpc
            ON p.policy_no = jpc.policy_no AND p.effective_dt = jpc.effective_dt AND pt.transaction_seq_no = jpc.transaction_seq_no
        LEFT JOIN json_pel_drivers AS jpd
            ON p.policy_no = jpd.policy_no AND p.effective_dt = jpd.effective_dt AND pt.transaction_seq_no = jpd.transaction_seq_no
        LEFT JOIN json_pel_objects AS jpo
            ON p.policy_no = jpo.policy_no AND p.effective_dt = jpo.effective_dt AND pt.transaction_seq_no = jpo.transaction_seq_no
        LEFT JOIN json_pel_prior_or_underly AS jppu
            ON p.policy_no = jppu.policy_no AND p.effective_dt = jppu.effective_dt AND pt.transaction_seq_no = jppu.transaction_seq_no
        LEFT JOIN (
				select broker_sk, broker_id, national_producer_no
				    ,ROW_NUMBER() OVER (PARTITION BY broker_id ORDER BY producer_sk DESC) AS rn
				from edw_core.tproducer
			) tprc
		ON p.broker_id = tprc.broker_id
		AND tprc.rn = 1
        WHERE b.ivans_y_account IS NOT NULL
        ;

        -- Start Insert process
        INSERT INTO [edw_integration].[policy_ivans_pel_feed](
            [MsgTypeCd_001],
            [BusinessPurposeTypeCd_002],
            [ActivityDt_003],
            [TransactionEffectiveDt_004],
            [IVANSXMLVersionCd_005],
            [CurCd_006],
            [BroadLOBCd_007],
            [SourceSystem_008],
            [ContractNumber_009],
            [ProducerSubCode_010],
            [InsurerId_011],
            [Surname_012],
            [GivenName_013],
            [OtherGivenName_014],
            [Prefix_015],
            [AddrTypeCd_016],
            [Addr1_017],
            [City_018],
            [StateProvCd_019],
            [StateProv_020],
            [PostalCode_021],
            [Country_022],
            [County_023],
            [PhoneTypeCd_024],
            [PhoneNumber_025],
            [EmailAddr_026],
            [GenderCd_027],
            [MaritalStatusCd_028],
            [BirthDt_029],
            [OccupationDesc_030],
            [InsuredOrPrincipalRoleCd_031],
            [InsuredOrPrincipalRoleDesc_032],
            [PolicyNumber_033],
            [BillingAccountNumber_034],
            [BroadLOBCd_035],
            [LOBCd_036],
            [NAICCd_037],
            [EffectiveDt_038],
            [ExpirationDt_039],
            [NumUnits_040],
            [Description_041],
            [ControllingStateProvCd_042],
            [BillingMethodCd_043],
            [Amt_044],
            [Amt_045],
            [OriginalPolicyInceptionDt_046],
            [PayorCd_047],
            [RenewalBillingMethodCd_048],
            [RenewalPayorCd_049],
            [Dummy_050],
            [Dummy_051],
            [Dummy_052],
            [Dummy_053],
            [Dummy_054],
            [Dummy_055],
            [Dummy_056],
            [CoverageCd_057],
            [FormatInteger_058],
            [MethodPaymentCd_059],
            [PaymentPlanCd_060],
            [Dummy_061],
            [Dummy_062],
            [Dummy_063],
            [Dummy_064],
            [Dummy_065],
            [Dummy_066],
            [Dummy_067],
            [Dummy_068],
            [Dummy_069],
            [Dummy_070],
            [Dummy_071],
            [Dummy_072],
            [LOBCd_073],
            [NAICCd_074],
            [LocationRef_075],
            [RiskType_076],
            [CommercialName_077],
            [PEL_Locations],
            [PEL_Coverages],
            [PEL_Drivers],
            [PEL_Objects],
            [PEL_Prior_or_Underly],
            [transaction_seq_no],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [NIPRid_200]

        )
        SELECT 
                [MsgTypeCd_001],
                [BusinessPurposeTypeCd_002],
                [ActivityDt_003],
                [TransactionEffectiveDt_004],
                [IVANSXMLVersionCd_005],
                [CurCd_006],
                [BroadLOBCd_007],
                [SourceSystem_008],
                [ContractNumber_009],
                [ProducerSubCode_010],
                [InsurerId_011],
                [Surname_012],
                [GivenName_013],
                [OtherGivenName_014],
                [Prefix_015],
                [AddrTypeCd_016],
                [Addr1_017],
                [City_018],
                [StateProvCd_019],
                [StateProv_020],
                [PostalCode_021],
                [Country_022],
                [County_023],
                CASE
                    WHEN [HomePhoneNumber_025] IS NOT NULL
                        AND LEN([HomePhoneNumber_025]) = 10
                        AND LEFT([HomePhoneNumber_025], 1) NOT IN ('0', '1')
                        THEN 'Home'
                    WHEN [MobilePhoneNumber_025] IS NOT NULL
                        AND LEN([MobilePhoneNumber_025]) = 10
                        AND LEFT([MobilePhoneNumber_025], 1) NOT IN ('0', '1')
                        THEN 'Mobile'
                    ELSE ''
                END AS [PhoneTypeCd_024],
                CASE
                    WHEN [HomePhoneNumber_025] IS NOT NULL
                        AND LEN([HomePhoneNumber_025]) = 10
                        AND LEFT([HomePhoneNumber_025], 1) NOT IN ('0', '1')
                        THEN [HomePhoneNumber_025]
                    WHEN [MobilePhoneNumber_025] IS NOT NULL
                        AND LEN([MobilePhoneNumber_025]) = 10
                        AND LEFT([MobilePhoneNumber_025], 1) NOT IN ('0', '1')
                        THEN [MobilePhoneNumber_025]
                    ELSE ''
                END AS [PhoneNumber_025],
                [EmailAddr_026],
                [GenderCd_027],
                [MaritalStatusCd_028],
                [BirthDt_029],
                [OccupationDesc_030],
                [InsuredOrPrincipalRoleCd_031],
                [InsuredOrPrincipalRoleDesc_032],
                [PolicyNumber_033],
                [BillingAccountNumber_034],
                [BroadLOBCd_035],
                [LOBCd_036],
                [NAICCd_037],
                [EffectiveDt_038],
                [ExpirationDt_039],
                [NumUnits_040],
                [Description_041],
                [ControllingStateProvCd_042],
                [BillingMethodCd_043],
                [Amt_044],
                [Amt_045],
                [OriginalPolicyInceptionDt_046],
                [PayorCd_047],
                [RenewalBillingMethodCd_048],
                [RenewalPayorCd_049],
                [Dummy_050],
                [Dummy_051],
                [Dummy_052],
                [Dummy_053],
                [Dummy_054],
                [Dummy_055],
                [Dummy_056],
                [CoverageCd_057],
                [FormatInteger_058],
                [MethodPaymentCd_059],
                [PaymentPlanCd_060],
                [Dummy_061],
                [Dummy_062],
                [Dummy_063],
                [Dummy_064],
                [Dummy_065],
                [Dummy_066],
                [Dummy_067],
                [Dummy_068],
                [Dummy_069],
                [Dummy_070],
                [Dummy_071],
                [Dummy_072],
                [LOBCd_073],
                [NAICCd_074],
                [LocationRef_075],
                [RiskType_076],
                [CommercialName_077],
                [PEL_Locations],
                [PEL_Coverages],
                [PEL_Drivers],
                [PEL_Objects],
                [PEL_Prior_or_Underly],
                [transaction_seq_no],
                [create_ts],
                [update_ts],
                [etl_audit_sk],
                [NIPRid_200]
        FROM [edw_temp].[policy_ivans_pel_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(policy_history_transaction_ts) FROM edw_temp.[policy_ivans_pel_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_pel_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_pel_feed_temp2];

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
