SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2024-05-18
-- Description: This stored procedure insert info related to claim_clue_auto_feed.
-- =============================================
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
                a.item_sk,
                b.transaction_ts,
                CASE 
                    WHEN (a.subro_expense_paid_amt + a.subro_recovery_amt) < 0 THEN 'S'
                    WHEN a.claim_feature_status ='CLOSED' THEN 'C' 
                    ELSE 'O' 
                END AS [claimDisposition],
                CASE
                    WHEN claim_coverage_desc = 'Bodily Injury' THEN 'BI'
                    WHEN claim_coverage_desc = 'Collision' THEN 'CO'
                    WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
                    WHEN claim_coverage_desc = 'Glass' THEN 'GL'
                    WHEN claim_coverage_desc = 'Medical Expenses' THEN 'ME'
                    WHEN claim_coverage_desc = 'Medical Payment' THEN 'MP'
                    WHEN claim_coverage_desc = 'Other' THEN 'OT'
                    WHEN claim_coverage_desc = 'No-Fault' THEN 'OT'
                    WHEN claim_coverage_desc IS NULL THEN 'OT'
                    WHEN claim_coverage_desc = 'Property Damage' THEN 'PD'
                    WHEN claim_coverage_desc = 'Property Protection (MI Only)' THEN 'PD'
                    WHEN claim_coverage_desc = 'Personal Injury Protection' THEN 'PI'
                    WHEN claim_coverage_desc = 'Rental Reimbursement' THEN 'RR'
                    WHEN claim_coverage_desc = 'Rental' THEN 'RR'
                    WHEN claim_coverage_desc = 'Spousal Liability' THEN 'SL'
                    WHEN claim_coverage_desc = 'Towing & Labor ' THEN 'TL'
                    WHEN claim_coverage_desc = 'Towing' THEN 'TL'
                    WHEN claim_coverage_desc = 'Uninsured Motorist' THEN 'UM'
                    WHEN claim_coverage_desc = 'Underinsured Motorist' THEN 'UN'
                    WHEN claim_coverage_desc = 'Uninsured / Underinsured Motorist' THEN 'UN'
                    WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TI'
                    ELSE 'OT'
                END AS [ClaimType],
                SUM(
                    COALESCE(
                            (
                                a.loss_paid_amt             + 
                                a.expense_paid_amt          + 
                                a.adjusting_other_paid_amt  + 
                                a.subro_recovery_amt        + 
                                a.salvage_recovery_amt      + 
                                a.salvage_expense_paid_amt  + 
                                a.subro_expense_paid_amt    + 
                                a.refund_indemnity_paid_amt + 
                                a.refund_expense_paid_amt
                            ), 0)
                    ) AS [claimAmount]
            FROM edw_core.tclaim_feature AS a
            INNER JOIN 
                (
                    SELECT claim_feature_sk, MAX(transaction_ts) AS transaction_ts
                    FROM edw_core.tclaim_transaction
                    GROUP BY claim_feature_sk
                ) AS b ON a.claim_feature_sk = b.claim_feature_sk
            WHERE a.source_system_sk = 3
            AND a.product_sk = 3
            AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
            GROUP BY
                a.claim_sk,
                a.item_sk,
                b.transaction_ts,
                CASE 
                    WHEN (a.subro_expense_paid_amt + a.subro_recovery_amt) < 0 THEN 'S'
                    WHEN a.claim_feature_status ='CLOSED' THEN 'C' 
                    ELSE 'O' 
                END,
                CASE
                    WHEN claim_coverage_desc = 'Bodily Injury' THEN 'BI'
                    WHEN claim_coverage_desc = 'Collision' THEN 'CO'
                    WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
                    WHEN claim_coverage_desc = 'Glass' THEN 'GL'
                    WHEN claim_coverage_desc = 'Medical Expenses' THEN 'ME'
                    WHEN claim_coverage_desc = 'Medical Payment' THEN 'MP'
                    WHEN claim_coverage_desc = 'Other' THEN 'OT'
                    WHEN claim_coverage_desc = 'No-Fault' THEN 'OT'
                    WHEN claim_coverage_desc IS NULL THEN 'OT'
                    WHEN claim_coverage_desc = 'Property Damage' THEN 'PD'
                    WHEN claim_coverage_desc = 'Property Protection (MI Only)' THEN 'PD'
                    WHEN claim_coverage_desc = 'Personal Injury Protection' THEN 'PI'
                    WHEN claim_coverage_desc = 'Rental Reimbursement' THEN 'RR'
                    WHEN claim_coverage_desc = 'Rental' THEN 'RR'
                    WHEN claim_coverage_desc = 'Spousal Liability' THEN 'SL'
                    WHEN claim_coverage_desc = 'Towing & Labor ' THEN 'TL'
                    WHEN claim_coverage_desc = 'Towing' THEN 'TL'
                    WHEN claim_coverage_desc = 'Uninsured Motorist' THEN 'UM'
                    WHEN claim_coverage_desc = 'Underinsured Motorist' THEN 'UN'
                    WHEN claim_coverage_desc = 'Uninsured / Underinsured Motorist' THEN 'UN'
                    WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TI'
                    ELSE 'OT'
                END
        )

        SELECT  
            '' AS [PolicyHolderNamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.last_nm ELSE cu.customer_nm END AS [PolicyHolderNameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.first_nm ELSE cu.customer_nm END AS [PolicyHolderNameFirst],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.middle_nm ELSE cu.customer_nm END AS [PolicyHolderNameMiddle],
            '' AS [PolicyHolderNameSuffix],
            SUBSTRING(p.mailing_address_line1, 1, PATINDEX('%[^0-9]%', p.mailing_address_line1 + 'x') - 1) AS [PolicyHolderMailAddrHseNum],
            LEFT(TRIM(SUBSTRING(p.mailing_address_line1, PATINDEX('%[^0-9]%', p.mailing_address_line1), 30)),20) AS [PolicyHolderMailAddressStreetName],
            p.mailing_address_unit_no AS [PolicyHolderMailAddressAptNum],
            p.mailing_address_city_nm AS [PolicyHolderMailAddressCity],
            p.mailing_address_state_cd AS [PolicyHolderMailAddressState],
            LEFT(p.mailing_address_zip_cd,5) AS [PolicyHolderMailAddressZip],
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
            NULL AS [PolicyHolder2SSN],
            NULL AS [PolicyHolder2DOB],
            '' AS [PolicyHolder2DriversLicenseNum],
            '' AS [PolicyHolder2DriversLicenseState],
            '' AS [PolicyHolder2Sex],
            -- pi2.prefix AS [PolicyHolder2NamePrefix],
            -- CASE WHEN cu.insured_type = 'Individual' THEN pi2.last_nm ELSE pi2.insured_nm END AS [PolicyHolder2NameLast],
            -- CASE WHEN cu.insured_type = 'Individual' THEN pi2.first_nm ELSE pi2.insured_nm END AS [PolicyHolder2NameFirst],
            -- CASE WHEN cu.insured_type = 'Individual' THEN pi2.middle_nm ELSE pi2.insured_nm END AS [PolicyHolder2NameMiddle],
            -- pi2.suffix AS [PolicyHolder2NameSuffix],
            -- '' AS [PolicyHolder2SSN],
            -- FORMAT(pi2.birth_dt, 'MMddyyyy') AS [PolicyHolder2DOB],
            -- ad.license_no AS [PolicyHolder2DriversLicenseNum],
            -- ad.license_state_nm AS [PolicyHolder2DriversLicenseState],
            -- CASE 
            --     WHEN ad.gender = 'Male' THEN 'M'
            --     WHEN ad.gender = 'Female' THEN 'F' 
            -- END AS [PolicyHolder2Sex],
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
            END AS [PolicyType],
            '' AS [Filler_reservedForFutureUse6],
            c.claim_no AS [ClaimNumber],
            cf.[ClaimType],
            FORMAT(c.loss_dt, 'MMddyyyy') AS [ClaimDate],
            CAST(cf.[claimAmount] AS INT) AS [ClaimAmount],
            'A' AS [ClaimReportingStatus],
            av.vehicle_vin AS [InsuredVehicleVIN],
            av.vehicle_model_year AS [InsuredVehicleModelYear],
            CASE
                WHEN av.vehicle_make IS NOT NULL AND av.vehicle_model IS NOT NULL THEN LEFT(CONCAT(av.vehicle_make, '-' ,av.vehicle_model),20)
            END AS [InsuredVehicleMakeModel],
            '' AS [InsuredVehicleDisposition],
            cf.[claimDisposition] AS [ClaimDisposition],
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
        LEFT JOIN edw_core.tauto_vehicle AS av ON cf.item_sk = av.auto_vehicle_sk
        -- LEFT JOIN edw_core.tauto_driver AS ad ON p.policy_no = ad.policy_no AND p.effective_dt = ad.effective_dt
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
            UPPER(ISNULL([PolicyHolderNamePrefix],'')) AS [PolicyHolderNamePrefix],
            UPPER(ISNULL([PolicyHolderNameLast],'')) AS [PolicyHolderNameLast],
            UPPER(ISNULL([PolicyHolderNameFirst],'')) AS [PolicyHolderNameFirst],
            UPPER(ISNULL([PolicyHolderNameMiddle],'')) AS [PolicyHolderNameMiddle],
            UPPER(ISNULL([PolicyHolderNameSuffix],'')) AS [PolicyHolderNameSuffix],
            UPPER(ISNULL([PolicyHolderMailAddrHseNum],'')) AS [PolicyHolderMailAddrHseNum],
            UPPER(ISNULL([PolicyHolderMailAddressStreetName],'')) AS [PolicyHolderMailAddressStreetName],
            UPPER(ISNULL([PolicyHolderMailAddressAptNum],'')) AS [PolicyHolderMailAddressAptNum],
            UPPER(ISNULL([PolicyHolderMailAddressCity],'')) AS [PolicyHolderMailAddressCity],
            UPPER(ISNULL([PolicyHolderMailAddressState],'')) AS [PolicyHolderMailAddressState],
            RIGHT('00000' + ISNULL([policyHolderMailAddressZip],'0'), 5) AS [policyHolderMailAddressZip],
	        RIGHT('0000' + ISNULL([policyHolderMailAddressZipPlus4],'0'), 4) AS [policyHolderMailAddressZipPlus4],
            RIGHT('0000000000' + ISNULL([Filler_reservedForFutureUse1],'0'), 10) AS [Filler_reservedForFutureUse1],
            RIGHT('000000000' + ISNULL([PolicyHolderSSN],'0'), 9) AS [PolicyHolderSSN],
            UPPER(ISNULL([PolicyHolderDOB],'')) AS [PolicyHolderDOB],
            UPPER(ISNULL([PolicyHolderDriversLicenseNum],'')) AS [PolicyHolderDriversLicenseNum],
            UPPER(ISNULL([PolicyHolderDriversLicenseState],'')) AS [PolicyHolderDriversLicenseState],
            UPPER(ISNULL([PolicyHolderSex],'')) AS [PolicyHolderSex],
            UPPER(ISNULL([Filler_reservedForFutureUse2],'')) AS [Filler_reservedForFutureUse2],
            UPPER(ISNULL([PolicyHolder2NamePrefix],'')) AS [PolicyHolder2NamePrefix],
            UPPER(ISNULL([PolicyHolder2NameLast],'')) AS [PolicyHolder2NameLast],
            UPPER(ISNULL([PolicyHolder2NameFirst],'')) AS [PolicyHolder2NameFirst],
            UPPER(ISNULL([PolicyHolder2NameMiddle],'')) AS [PolicyHolder2NameMiddle],
            UPPER(ISNULL([PolicyHolder2NameSuffix],'')) AS [PolicyHolder2NameSuffix],
            RIGHT('000000000' + ISNULL([PolicyHolder2SSN],'0'), 9) AS [PolicyHolder2SSN],
            RIGHT('00000000' + ISNULL([PolicyHolder2DOB],'0'), 8) AS [PolicyHolder2DOB],
            UPPER(ISNULL([PolicyHolder2DriversLicenseNum],'')) AS [PolicyHolder2DriversLicenseNum],
            UPPER(ISNULL([PolicyHolder2DriversLicenseState],'')) AS [PolicyHolder2DriversLicenseState],
            UPPER(ISNULL([PolicyHolder2Sex],'')) AS [PolicyHolder2Sex],
            UPPER(ISNULL([Filler_reservedForFutureUse3],'')) AS [Filler_reservedForFutureUse3],
            UPPER(ISNULL([VehicleOperatorNamePrefix],'')) AS [VehicleOperatorNamePrefix],
            UPPER(ISNULL([VehicleOperatorNameLast],'')) AS [VehicleOperatorNameLast],
            UPPER(ISNULL([VehicleOperatorNameFirst],'')) AS [VehicleOperatorNameFirst],
            UPPER(ISNULL([VehicleOperatorNameMiddle],'')) AS [VehicleOperatorNameMiddle],
            UPPER(ISNULL([VehicleOperatorNameSuffix],'')) AS [VehicleOperatorNameSuffix],
            UPPER(ISNULL([VehicleOperatorAddrHseNum],'')) AS [VehicleOperatorAddrHseNum],
            UPPER(ISNULL([VehicleOperatorAddrStreetName],'')) AS [VehicleOperatorAddrStreetName],
            UPPER(ISNULL([VehicleOperatorAddrAptNum],'')) AS [VehicleOperatorAddrAptNum],
            UPPER(ISNULL([VehicleOperatorAddrCity],'')) AS [VehicleOperatorAddrCity],
            UPPER(ISNULL([VehicleOperatorAddrState],'')) AS [VehicleOperatorAddrState],
            RIGHT('00000' + ISNULL([VehicleOperatorAddrZipCode],'0'), 5) AS [VehicleOperatorAddrZipCode],
	        RIGHT('0000' + ISNULL([VehicleOperatorAddrZipPlus4],'0'), 4) AS [VehicleOperatorAddrZipPlus4],
            UPPER(ISNULL([Filler_reservedForFutureUse4],'')) AS [Filler_reservedForFutureUse4],
            RIGHT('000000000' + ISNULL([VehicleOperatorSSN],'0'), 9) AS [VehicleOperatorSSN],
            RIGHT('00000000' + ISNULL([VehicleOperatorDOB],'0'), 8) AS [VehicleOperatorDOB],
            UPPER(ISNULL([VehicleOperatorDriversLicenseNum],'')) AS [VehicleOperatorDriversLicenseNum],
            UPPER(ISNULL([VehicleOperatorDriversLicenseState],'')) AS [VehicleOperatorDriversLicenseState],
            UPPER(ISNULL([VehicleOperatorSex],'')) AS [VehicleOperatorSex],
            UPPER(ISNULL([VehicleOperatorRelationship],'')) AS [VehicleOperatorRelationship],
            UPPER(ISNULL([Filler_reservedForFutureUse5],'')) AS [Filler_reservedForFutureUse5],
            RIGHT('00000' + ISNULL([contribCompany],'0'), 5) AS [contribCompany],
            UPPER(ISNULL([PolicyNumber],'')) AS [PolicyNumber],
            UPPER(ISNULL([PolicyType],'')) AS [PolicyType],
            UPPER(ISNULL([Filler_reservedForFutureUse6],'')) AS [Filler_reservedForFutureUse6],
            UPPER(ISNULL([ClaimNumber],'')) AS [ClaimNumber],
            UPPER(ISNULL([ClaimType],'')) AS [ClaimType],
            RIGHT('00000000' + ISNULL([claimDate],'0'), 8) AS [claimDate],
            RIGHT('000000000' + CAST(ISNULL([claimAmount],'0') AS nvarchar(9)), 9) AS [claimAmount],
            UPPER(ISNULL([ClaimReportingStatus],'')) AS [ClaimReportingStatus],
            UPPER(ISNULL([InsuredVehicleVIN],'')) AS [InsuredVehicleVIN],
            RIGHT('0000' + ISNULL([InsuredVehicleModelYear],'0'), 4) AS [InsuredVehicleModelYear],
            UPPER(ISNULL([InsuredVehicleMakeModel],'')) AS [InsuredVehicleMakeModel],
            UPPER(ISNULL([InsuredVehicleDisposition],'')) AS [InsuredVehicleDisposition],
            UPPER(ISNULL([ClaimDisposition],'')) AS [ClaimDisposition],
            UPPER(ISNULL([FaultIndicator],'')) AS [FaultIndicator],
            RIGHT('00000000' + ISNULL([DateofFirstPayment],'0'), 8) AS [DateofFirstPayment],
            UPPER(ISNULL([CAIndicator1],'')) AS [CAIndicator1],
            UPPER(ISNULL([CAIndicator2],'')) AS [CAIndicator2],
            UPPER(ISNULL([CAIndicator3],'')) AS [CAIndicator3],
            UPPER(ISNULL([CAIndicator4],'')) AS [CAIndicator4],
            UPPER(ISNULL([Filler_reservedForFutureUse7],'')) AS [Filler_reservedForFutureUse7],
            UPPER(ISNULL([RecordVersionNumber],'')) AS [RecordVersionNumber],
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
