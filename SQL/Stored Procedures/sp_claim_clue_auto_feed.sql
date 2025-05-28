SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2024-05-18
-- Description: This stored procedure insert info related to claim_clue_auto_feed.
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 01-03-2025				Alberto Almario				1. Add snasheet mapping to ClaimType column.
-- 01-21-2025               Rushin Shah                 2. Updated the claim amount field logic
-- 04-30-2025               Alberto Almario             3. Include snapsheet claims and change logic for item_sk
-- 05-08-2025               Alberto Almario             4. Add logic to retrieve the address for OneShield policies.
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_clue_auto_feed]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT = NULL
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
		DROP TABLE IF EXISTS [edw_temp].[claim_clue_auto_feed_temp1];

        WITH 
        customer AS (
            SELECT 
                customer_id,
                insured_type,
                LEFT(first_nm,20) AS first_nm,
                LEFT(last_nm,20) AS last_nm,
                LEFT(middle_nm,15) AS middle_nm,
                LEFT(customer_nm,15) AS customer_nm,
                birth_dt,
                RIGHT(REPLACE(TRANSLATE(home_phone_no, '+-/()#', '      '), ' ', ''), 10) AS home_phone_no
            FROM edw_core.tcustomer
        )
        ,policy_insured_2 AS (
            SELECT 
                pi.policy_insured_sk,
                pi.policy_no,
                pi.prefix,
                pi.suffix,
                LEFT(pi.first_nm,20) AS first_nm,
                LEFT(pi.last_nm,20) AS last_nm,
                LEFT(pi.middle_nm,20) AS middle_nm,
                LEFT(pi.insured_nm,20) AS insured_nm,
                pi.birth_dt  
            FROM edw_core.tpolicy_insured AS pi
            INNER JOIN 
                (
                    SELECT 
                        policy_no,
                        MAX(policy_insured_sk) AS max_policy_insured_sk
                    FROM edw_core.tpolicy_insured 
                    WHERE primary_insured_in = 'No' 
                    GROUP BY 
                        policy_no
                ) AS pim
            ON pi.policy_insured_sk = pim.max_policy_insured_sk
        )
        ,claims AS (
            SELECT 
                c.claim_sk
                ,c.claim_no
                ,c.policy_sk
                ,c.policy_no
                ,c.cause_of_loss_sk
                ,c.catastrophe_sk
                ,c.loss_dt
            FROM edw_core.tclaim AS c
        )
        ,claim_feature AS (
            SELECT 
                a.claim_sk,
                b.transaction_ts,
                SUM(a.subrogation_expense_recovery_amt + a.subrogation_recovery_amt) AS sum_subro_exp_rec_amt,
                MAX(
                    CASE 
                        WHEN a.claim_feature_status = 'CLOSED' THEN 1
                        ELSE 2
                    END
                )
                AS claim_feature_status_no,
                CASE
                    WHEN claim_coverage_desc = 'Combined Single Limits' THEN 'BI'
                    WHEN claim_coverage_desc = 'Collision' THEN 'CO'
                    WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
                    WHEN claim_coverage_desc = 'Full Glass' THEN 'GL'
                    WHEN claim_coverage_desc = 'Medical Payments' THEN 'MP'
                    WHEN claim_coverage_desc = 'PIP' THEN 'OT'
                    WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
                    WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
                    WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UN'
                    ELSE 'OT'
                END AS [ClaimType],
                SUM(
                    COALESCE(
                            (
                                a.loss_paid_amt                     +
                                a.expense_paid_amt                  +
                                a.defense_paid_amt                  +
                                a.overpayment_recovery_amt          +
                                a.overpayment_expense_recovery_amt  +
                                a.overpayment_defense_recovery_amt
                            ), 0)
                    ) AS [claimAmount]
            FROM edw_core.tclaim_feature AS a
            INNER JOIN 
                (
                    SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
                    FROM edw_core.tclaim_transaction
                    GROUP BY claim_sk
                ) AS b ON a.claim_sk = b.claim_sk
            WHERE a.source_system_sk in (3,5)
            AND a.product_sk = 3
            AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
            GROUP BY
                a.claim_sk,
                b.transaction_ts,
                CASE
                    WHEN claim_coverage_desc = 'Combined Single Limits' THEN 'BI'
                    WHEN claim_coverage_desc = 'Collision' THEN 'CO'
                    WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
                    WHEN claim_coverage_desc = 'Full Glass' THEN 'GL'
                    WHEN claim_coverage_desc = 'Medical Payments' THEN 'MP'
                    WHEN claim_coverage_desc = 'PIP' THEN 'OT'
                    WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
                    WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
                    WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UN'
                    ELSE 'OT'
                END
        )
        ,claim_feature_item AS (
            SELECT 
                claim_sk, item_sk, rc
            FROM (
                SELECT 
                    claim_sk,
                    item_sk,
                    rc,
                    ROW_NUMBER() OVER (PARTITION BY claim_sk ORDER BY rc DESC, item_sk DESC) AS rn
                FROM (
                    SELECT a.claim_sk, a.item_sk, COUNT(*) AS rc
                    FROM edw_core.tclaim_feature a
                    INNER JOIN claim_feature b ON a.claim_sk = b.claim_sk
                    GROUP BY a.claim_sk, a.item_sk
                ) AS counts
            ) AS ranked
            WHERE rn = 1
        )

        SELECT  
            '' AS [PolicyHolderNamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.last_nm ELSE cu.customer_nm END AS [PolicyHolderNameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.first_nm ELSE cu.customer_nm END AS [PolicyHolderNameFirst],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.middle_nm ELSE cu.customer_nm END AS [PolicyHolderNameMiddle],
            '' AS [PolicyHolderNameSuffix],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN osp.home_no 
                ELSE SUBSTRING(p.mailing_address_line1, 1, PATINDEX('%[^0-9]%', p.mailing_address_line1 + 'x') - 1) 
            END AS [PolicyHolderMailAddrHseNum],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN LEFT(osp.address_nm, 20) 
                ELSE LEFT(TRIM(SUBSTRING(p.mailing_address_line1, PATINDEX('%[^0-9]%', p.mailing_address_line1), 30)), 20) 
            END AS [PolicyHolderMailAddressStreetName],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN LEFT(osp.unit_no, 5) 
                ELSE LEFT(p.mailing_address_unit_no, 5) 
            END AS [PolicyHolderMailAddressAptNum],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN LEFT(osp.city_nm, 20) 
                ELSE LEFT(p.mailing_address_city_nm, 20) 
            END AS [PolicyHolderMailAddressCity],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN LEFT(osp.state_cd, 2) 
                ELSE LEFT(p.mailing_address_state_cd, 2) 
            END AS [PolicyHolderMailAddressState],
            CASE 
                WHEN p.mailing_address_line1 IS NULL THEN LEFT(osp.zip_cd, 5) 
                ELSE LEFT(p.mailing_address_zip_cd,5) 
            END AS [PolicyHolderMailAddressZip],
            '' AS [PolicyHolderMailAddressZipPlus4],
            '' AS [Filler_reservedForFutureUse1],
            '' AS [PolicyHolderSSN],
            FORMAT(cu.birth_dt, 'MMddyyyy') AS [PolicyHolderDOB],
            '' AS [PolicyHolderDriversLicenseNum],
            '' AS [PolicyHolderDriversLicenseState],
            '' AS [PolicyHolderSex],
            '' AS [Filler_reservedForFutureUse2],
            '' AS [PolicyHolder2NamePrefix],
            '' AS [PolicyHolder2NameLast],
            '' AS [PolicyHolder2NameFirst],
            '' AS [PolicyHolder2NameMiddle],
            '' AS [PolicyHolder2NameSuffix],
            '' AS [PolicyHolder2SSN],
            '' AS [PolicyHolder2DOB],
            '' AS [PolicyHolder2DriversLicenseNum],
            '' AS [PolicyHolder2DriversLicenseState],
            '' AS [PolicyHolder2Sex],
            '' AS [Filler_reservedForFutureUse3],
            '' AS [VehicleOperatorNamePrefix],
            '' AS [VehicleOperatorNameLast],
            '' AS [VehicleOperatorNameFirst],
            '' AS [VehicleOperatorNameMiddle],
            '' AS [VehicleOperatorNameSuffix],
            '' AS [VehicleOperatorAddrHseNum],
            '' AS [VehicleOperatorAddrStreetName],
            '' AS [VehicleOperatorAddrAptNum],
            '' AS [VehicleOperatorAddrCity],
            '' AS [VehicleOperatorAddrState],
            '' AS [VehicleOperatorAddrZipCode],
            '' AS [VehicleOperatorAddrZipPlus4],
            '' AS [Filler_reservedForFutureUse4],
            '' AS [VehicleOperatorSSN],
            '' AS [VehicleOperatorDOB],
            '' AS [VehicleOperatorDriversLicenseNum],
            '' AS [VehicleOperatorDriversLicenseState],
            '' AS [VehicleOperatorSex],
            '' AS [VehicleOperatorRelationship],
            '' AS [Filler_reservedForFutureUse5],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '20564'
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '20586'
                ELSE ' ' 
            END AS [contribCompany],
            p.policy_no AS [PolicyNumber],
            CASE 
                WHEN av.vehicle_type = 'Collector Car' THEN 'PA'
                WHEN av.vehicle_type = 'Dune Buggy' THEN 'CY'
                WHEN av.vehicle_type = 'Motor Home' THEN 'MH'
                WHEN av.vehicle_type = 'Motorcycles / Mopeds / Scooter / Go Karts' THEN 'CY'
                WHEN av.vehicle_type = 'Private Passenger Auto' THEN 'PA'
                WHEN av.vehicle_type = 'Recreational Trailer' THEN 'PA'
                WHEN av.vehicle_type = 'Snowmobile / ATV' THEN 'CY'
                WHEN av.vehicle_type = 'Golf Cart' THEN 'PA'
                ELSE 'PA'
            END AS [PolicyType],
            '' AS [Filler_reservedForFutureUse6],
            c.claim_no AS [ClaimNumber],
            cf.[ClaimType],
            FORMAT(c.loss_dt, 'MMddyyyy') AS [ClaimDate],
            CASE 
                WHEN cf.[claimAmount] < 0 THEN '000000000'
                ELSE RIGHT('000000000' + REPLACE(CAST(cf.[claimAmount] AS VARCHAR(10)), '.', ''), 9)
            END AS [ClaimAmount],
            'A' AS [ClaimReportingStatus],
            av.vehicle_vin AS [InsuredVehicleVIN],
            av.vehicle_model_year AS [InsuredVehicleModelYear],
            CASE
                WHEN av.vehicle_make IS NOT NULL AND av.vehicle_model IS NOT NULL THEN LEFT(CONCAT(av.vehicle_make, '-' ,av.vehicle_model),20)
            END AS [InsuredVehicleMakeModel],
            '' AS [InsuredVehicleDisposition],
            CASE 
                WHEN cf.sum_subro_exp_rec_amt < 0 THEN 'S'
                WHEN cf.claim_feature_status_no = 1 THEN 'C' --1 = Closed
                ELSE 'O' 
            END AS [ClaimDisposition],
            '' AS [FaultIndicator],
            '' AS [DateofFirstPayment],
            '' AS [CAIndicator1],
            '' AS [CAIndicator2],
            '' AS [CAIndicator3],
            '' AS [CAIndicator4],
            '' AS [Filler_reservedForFutureUse7],
            '2' AS [recordVersionNumber],
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE 
                WHEN (SELECT MAX(report_end_date) FROM [edw_integration].[claim_clue_auto_feed]) IS NULL THEN '2020-06-29 00:00:00'
                ELSE (SELECT DATEADD(day, 1, MAX(report_end_date)) FROM [edw_integration].[claim_clue_auto_feed])
            END AS [report_start_date],
            CONVERT(datetime, CONVERT(date, DATEADD(day, -1, GETDATE()))) AS [report_end_date],
            cf.transaction_ts
        INTO [edw_temp].[claim_clue_auto_feed_temp1] 
        FROM claim_feature AS cf
        INNER JOIN claims AS c ON cf.claim_sk = c.claim_sk
        INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
        LEFT JOIN edw_stage.OneShieldPolicy_clue AS osp ON c.policy_no = osp.policy_no
        LEFT JOIN claim_feature_item AS cfi ON cf.claim_sk = cfi.claim_sk
        LEFT JOIN edw_core.tauto_vehicle AS av ON cfi.item_sk = av.auto_vehicle_sk
        LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
        LEFT JOIN policy_insured_2 AS pi2 ON c.policy_no = pi2.policy_no
        WHERE p.product_cd IN ('AU')
        ;

                
        -- Start Insert process
        INSERT INTO [edw_integration].[claim_clue_auto_feed](
            [PolicyHolderNamePrefix],
            [PolicyHolderNameLast],
            [PolicyHolderNameFirst],
            [PolicyHolderNameMiddle],
            [PolicyHolderNameSuffix],
            [PolicyHolderMailAddrHseNum],
            [PolicyHolderMailAddressStreetName],
            [PolicyHolderMailAddressAptNum],
            [PolicyHolderMailAddressCity],
            [PolicyHolderMailAddressState],
            [PolicyHolderMailAddressZip],
            [PolicyHolderMailAddressZipPlus4],
            [Filler_reservedForFutureUse1],
            [PolicyHolderSSN],
            [PolicyHolderDOB],
            [PolicyHolderDriversLicenseNum],
            [PolicyHolderDriversLicenseState],
            [PolicyHolderSex],
            [Filler_reservedForFutureUse2],
            [PolicyHolder2NamePrefix],
            [PolicyHolder2NameLast],
            [PolicyHolder2NameFirst],
            [PolicyHolder2NameMiddle],
            [PolicyHolder2NameSuffix],
            [PolicyHolder2SSN],
            [PolicyHolder2DOB],
            [PolicyHolder2DriversLicenseNum],
            [PolicyHolder2DriversLicenseState],
            [PolicyHolder2Sex],
            [Filler_reservedForFutureUse3],
            [VehicleOperatorNamePrefix],
            [VehicleOperatorNameLast],
            [VehicleOperatorNameFirst],
            [VehicleOperatorNameMiddle],
            [VehicleOperatorNameSuffix],
            [VehicleOperatorAddrHseNum],
            [VehicleOperatorAddrStreetName],
            [VehicleOperatorAddrAptNum],
            [VehicleOperatorAddrCity],
            [VehicleOperatorAddrState],
            [VehicleOperatorAddrZipCode],
            [VehicleOperatorAddrZipPlus4],
            [Filler_reservedForFutureUse4],
            [VehicleOperatorSSN],
            [VehicleOperatorDOB],
            [VehicleOperatorDriversLicenseNum],
            [VehicleOperatorDriversLicenseState],
            [VehicleOperatorSex],
            [VehicleOperatorRelationship],
            [Filler_reservedForFutureUse5],
            [contribCompany],
            [PolicyNumber],
            [PolicyType],
            [Filler_reservedForFutureUse6],
            [ClaimNumber],
            [ClaimType],
            [ClaimDate],
            [ClaimAmount],
            [ClaimReportingStatus],
            [InsuredVehicleVIN],
            [InsuredVehicleModelYear],
            [InsuredVehicleMakeModel],
            [InsuredVehicleDisposition],
            [ClaimDisposition],
            [FaultIndicator],
            [DateofFirstPayment],
            [CAIndicator1],
            [CAIndicator2],
            [CAIndicator3],
            [CAIndicator4],
            [Filler_reservedForFutureUse7],
            [RecordVersionNumber],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [report_start_date],
            [report_end_date]
        )
        SELECT 
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderNamePrefix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderNamePrefix],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderNameLast],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderNameLast],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderNameFirst],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderNameFirst],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderNameMiddle],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderNameMiddle],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderNameSuffix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderNameSuffix],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderMailAddrHseNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderMailAddrHseNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderMailAddressStreetName],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderMailAddressStreetName],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderMailAddressAptNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderMailAddressAptNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderMailAddressCity],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderMailAddressCity],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderMailAddressState],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderMailAddressState],
            RIGHT('00000' + REPLACE(REPLACE(REPLACE(ISNULL([policyHolderMailAddressZip],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 5) AS [policyHolderMailAddressZip],
	        RIGHT('0000' + REPLACE(REPLACE(REPLACE(ISNULL([policyHolderMailAddressZipPlus4],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 4) AS [policyHolderMailAddressZipPlus4],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse1],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse1],
            RIGHT('000000000' + REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderSSN],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 9) AS [PolicyHolderSSN],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderDOB],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderDOB],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderDriversLicenseNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderDriversLicenseNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderDriversLicenseState],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderDriversLicenseState],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolderSex],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolderSex],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse2],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse2],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2NamePrefix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2NamePrefix],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2NameLast],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2NameLast],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2NameFirst],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2NameFirst],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2NameMiddle],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2NameMiddle],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2NameSuffix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2NameSuffix],
            RIGHT('000000000' + REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2SSN],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 9) AS [PolicyHolder2SSN],
            RIGHT('00000000' + REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2DOB],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 8) AS [PolicyHolder2DOB],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2DriversLicenseNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2DriversLicenseNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2DriversLicenseState],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2DriversLicenseState],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyHolder2Sex],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyHolder2Sex],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse3],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse3],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorNamePrefix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorNamePrefix],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorNameLast],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorNameLast],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorNameFirst],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorNameFirst],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorNameMiddle],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorNameMiddle],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorNameSuffix],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorNameSuffix],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrHseNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorAddrHseNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrStreetName],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorAddrStreetName],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrAptNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorAddrAptNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrCity],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorAddrCity],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrState],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorAddrState],
            RIGHT('00000' + REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrZipCode],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 5) AS [VehicleOperatorAddrZipCode],
	        RIGHT('0000' + REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorAddrZipPlus4],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 4) AS [VehicleOperatorAddrZipPlus4],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse4],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse4],
            RIGHT('000000000' + REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorSSN],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 9) AS [VehicleOperatorSSN],
            RIGHT('00000000' + REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorDOB],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 8) AS [VehicleOperatorDOB],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorDriversLicenseNum],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorDriversLicenseNum],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorDriversLicenseState],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorDriversLicenseState],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorSex],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorSex],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([VehicleOperatorRelationship],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [VehicleOperatorRelationship],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse5],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse5],
            RIGHT('00000' + REPLACE(REPLACE(REPLACE(ISNULL([contribCompany],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 5) AS [contribCompany],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyNumber],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyNumber],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([PolicyType],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [PolicyType],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse6],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse6],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([ClaimNumber],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [ClaimNumber],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([ClaimType],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [ClaimType],
            RIGHT('00000000' + REPLACE(REPLACE(REPLACE(ISNULL([claimDate],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 8) AS [claimDate],
            REPLACE(REPLACE(REPLACE(ISNULL([claimAmount],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0') AS [claimAmount],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([ClaimReportingStatus],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [ClaimReportingStatus],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([InsuredVehicleVIN],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [InsuredVehicleVIN],
            RIGHT('0000' + REPLACE(REPLACE(REPLACE(ISNULL([InsuredVehicleModelYear],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 4) AS [InsuredVehicleModelYear],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([InsuredVehicleMakeModel],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [InsuredVehicleMakeModel],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([InsuredVehicleDisposition],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [InsuredVehicleDisposition],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([ClaimDisposition],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [ClaimDisposition],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([FaultIndicator],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [FaultIndicator],
            RIGHT('00000000' + REPLACE(REPLACE(REPLACE(ISNULL([DateofFirstPayment],'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'), 8) AS [DateofFirstPayment],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([CAIndicator1],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [CAIndicator1],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([CAIndicator2],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [CAIndicator2],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([CAIndicator3],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [CAIndicator3],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([CAIndicator4],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [CAIndicator4],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([Filler_reservedForFutureUse7],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [Filler_reservedForFutureUse7],
            UPPER(REPLACE(REPLACE(REPLACE(ISNULL([RecordVersionNumber],''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')) AS [RecordVersionNumber],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [report_start_date],
            [report_end_date]
        FROM [edw_temp].[claim_clue_auto_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_ts) FROM edw_temp.[claim_clue_auto_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[claim_clue_auto_feed_temp1];

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
