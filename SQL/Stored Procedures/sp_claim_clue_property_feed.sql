SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2024-03-29
-- Description: This stored procedure insert info related to claim_clue_property_feed.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_clue_property_feed]
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
		DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp0];
        DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp2];
        

        WITH 
        location_address AS (
            SELECT 
                policy_no, 
                LEFT(TRIM(SUBSTRING(address_line_1, PATINDEX('%[^0-9]%', address_line_1), 30)),20) as address_line_1, 
                address_line_2, 
                SUBSTRING(address_line_1, 1, PATINDEX('%[^0-9]%', address_line_1 + 'x') - 1) as home_no, 
                unit_no, city_nm, state_cd, zip_cd 
            FROM edw_core.tpel_location
                UNION
            SELECT 
                policy_no, 
                LEFT(TRIM(SUBSTRING(address_line_1, PATINDEX('%[^0-9]%', address_line_1), 30)),20) as address_line_1, 
                address_line_2, 
                SUBSTRING(address_line_1, 1, PATINDEX('%[^0-9]%', address_line_1 + 'x') - 1) as home_no, 
                unit_no, city_nm, state_cd, zip_cd
            FROM edw_core.thome_location
                UNION
            SELECT 
                policy_no, 
                LEFT(TRIM(SUBSTRING(address_line_1, PATINDEX('%[^0-9]%', address_line_1), 30)),20) as address_line_1, 
                address_line_2, 
                SUBSTRING(address_line_1, 1, PATINDEX('%[^0-9]%', address_line_1 + 'x') - 1) as home_no, 
                unit_no, city_nm, state_cd, zip_cd
            FROM edw_core.tcollection_location
        )
        ,mortagee AS (
            SELECT 
                policy_no,
                mortgagee_nm,
                loan_no
            FROM edw_core.tmortgagee 
            WHERE mortgagee_type = 'First' 
            AND mortgagee_no = '1'
        )
        ,customer AS (
            SELECT 
                customer_id,
                insured_type,
                LEFT(first_nm,20) AS first_nm,
                LEFT(last_nm,20) AS last_nm,
                LEFT(customer_nm,20) AS customer_nm,
                birth_dt,
                RIGHT(REPLACE(TRANSLATE(home_phone_no, '+-/()#', '      '), ' ', ''), 10) AS home_phone_no
            FROM edw_core.tcustomer
        )
        ,policy_insured_2 AS (
            SELECT 
                pi.policy_insured_sk,
                pi.policy_no,
                LEFT(pi.first_nm,20) AS first_nm,
                LEFT(pi.last_nm,20) AS last_nm,
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
                ,ct.transaction_ts
                ,COALESCE(
                    (
                        c.loss_paid_amt             + 
                        c.expense_paid_amt          + 
                        c.adjusting_other_paid_amt  + 
                        c.subro_recovery_amt        + 
                        c.salvage_recovery_amt      + 
                        c.salvage_expense_paid_amt  + 
                        c.subro_expense_paid_amt    + 
                        c.refund_indemnity_paid_amt + 
                        c.refund_expense_paid_amt
                    ), 0
                ) AS [claimAmount]
                ,CASE 
                    WHEN (c.subro_expense_paid_amt + c.subro_recovery_amt) < 0 THEN 'S'
                    WHEN c.claim_status ='CLOSED' THEN 'C' 
                    ELSE 'O' 
                END AS [claimDisposition]
            FROM edw_core.tclaim AS c
            INNER JOIN 
                (
                    SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
                    FROM edw_core.tclaim_transaction
                    GROUP BY claim_sk
                ) AS ct ON c.claim_sk = ct.claim_sk
            WHERE c.source_system_sk = 3
            AND cast(ct.transaction_ts as datetime2(7)) > @last_source_extract_ts
        )

        SELECT  
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '20564'
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '20586'
                ELSE '00000' 
            END AS [contribCompany],
            c.claim_no AS [claimNumber],
            p.policy_no AS [policyNumber],
            CASE 
                WHEN p.product_cd IN ('HO','CO') THEN 'H'
                WHEN p.product_cd = 'LUX' THEN 'I'
                WHEN p.product_cd = 'PEL' THEN 'J'
                ELSE ''
            END AS [policyType],
            RIGHT('00000000' + FORMAT(c.loss_dt, 'MMddyyyy'), 8) AS [claimDate],
            CASE cof.cause_of_loss_desc
                WHEN 'Collapse' THEN 'OTHER'
                WHEN 'Damage by Animals' THEN 'PHYDA'
                WHEN 'Equipment Breakdown' THEN 'APPL'
                WHEN 'Fire' THEN 'FIRE'
                WHEN 'Flood' THEN 'FLOOD'
                WHEN 'Freezing' THEN 'FREEZ'
                WHEN 'Fungi/Mold' THEN 'MOLD'
                WHEN 'Glass Breakage' THEN 'PHYDA'
                WHEN 'Hail' THEN 'HAIL'
                WHEN 'Hurricane' THEN 'WIND'
                WHEN 'Ice Dam' THEN 'OTHER'
                WHEN 'Liability' THEN 'LIAB'
                WHEN 'Lightning' THEN 'LIGHT'
                WHEN 'Loss Assessment' THEN 'OTHER'
                WHEN 'Mysterious Disappearance' THEN 'DISAP'
                WHEN 'Named Storms Other than Hurricanes' THEN 'WIND'
                WHEN 'Power Outage' THEN 'OTHER'
                WHEN 'Service Line' 	 THEN 'EXTEN'
                WHEN 'Sewer and Drain' THEN 'ACCDL'
                WHEN 'Smoke' THEN 'SMOKE'
                WHEN 'Theft' THEN 'THEFT'
                WHEN 'Vandalism' THEN 'VMM'
                WHEN 'Water' THEN 'WATER'
                WHEN 'Wind' THEN 'WIND'
                WHEN 'Workers Compensation' THEN 'WC'
                WHEN 'Collision' THEN 'COLL'
                WHEN 'Other' THEN 'OTHER'
                WHEN 'Libel, Slander, Defamation of Character' THEN 'LIAB'
                WHEN 'Hit and Run' THEN 'COLL'
                WHEN 'Property Damage' THEN 'DAMAG'
                WHEN 'Fall, Slip, or Trip on Insured''s Exterior Premises' THEN 'SLIP'
                WHEN 'Boat / Jet Ski' THEN 'CRAFT' 
                ELSE 'OTHER'
            END AS [causeOfLoss],
            'U' AS [locationOfLoss],
            CASE 
                WHEN c.[claimAmount] < 0 THEN '-' + RIGHT('00000000' + REPLACE(CAST(ABS(c.[claimAmount]) AS VARCHAR(9)), '.', ''), 8)
                ELSE RIGHT('000000000' + REPLACE(CAST(c.[claimAmount] AS VARCHAR(10)), '.', ''), 9)
            END AS [claimAmount],
            'A' AS [claimReportingStatus],
            c.[claimDisposition],
            CASE WHEN cat.catastrophe_nm  IS NULL THEN 'N' ELSE 'Y' END AS [catastropheRelated],
            LEFT(m.mortgagee_nm, 30) AS [mortgageName],
            LEFT(m.loan_no, 15)  AS [mortgageLoanNumber],
            '' AS [filler_reservedforFutureUse],
            la.home_no AS [riskAddressHseNum],
            la.address_line_1 AS [riskAddressStreetName],
            LEFT(la.unit_no, 5) AS [riskAddressAptNum],
            LEFT(la.city_nm, 20) AS [riskAddressCity],
            la.state_cd AS [riskAddressState],
            RIGHT('00000' + la.zip_cd, 5) AS [riskAddressZip],
            '0000' AS [riskAddressZipPlus4], 
            SUBSTRING(p.mailing_address_line1, 1, PATINDEX('%[^0-9]%', p.mailing_address_line1 + 'x') - 1) AS [policyHolderMailAddrHseNum],
            LEFT(TRIM(SUBSTRING(p.mailing_address_line1, PATINDEX('%[^0-9]%', p.mailing_address_line1), 30)),20) AS [policyHolderMailAddressStreetName],
            LEFT(p.mailing_address_unit_no, 5) AS [policyHolderMailAddressAptNum],
            LEFT(p.mailing_address_city_nm, 20) AS [policyHolderMailAddressCity],
            p.mailing_address_state_cd AS [policyHolderMailAddressState],
            RIGHT('00000' + LEFT(p.mailing_address_zip_cd,5), 5) AS [policyHolderMailAddressZip],
            '0000' AS [policyHolderMailAddressZipPlus4],
            RIGHT('000' + SUBSTRING(cu.home_phone_no,1,3), 3) AS [policyHolderTelAreaCode],
            RIGHT('0000000' + SUBSTRING(cu.home_phone_no,4,7), 7) AS [policyHolderTelNumber],
            '' AS [filler_reservedforFutureUse1],
            '' AS [policyHolderNamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.last_nm ELSE cu.customer_nm END AS [policyHolderNameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.first_nm ELSE cu.customer_nm END AS [policyHolderNameFirst],
            '' AS [policyHolderNameMiddle],
            '' AS [policyHolderNameSuffix],
            '000000000' AS [policyHolderSSN],
            RIGHT('00000000' + FORMAT(cu.birth_dt, 'MMddyyyy'), 8) AS [policyHolderDOB],
            '' AS [policyHolderSex],
            '' AS [filler_reservedforFutureUse2],
            '' AS [policyHolder2NamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN pi2.last_nm ELSE pi2.insured_nm END AS [policyHolder2NameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN pi2.first_nm ELSE pi2.insured_nm END AS [policyHolder2NameFirst],
            '' AS [policyHolder2NameMiddle],
            '' AS [policyHolder2NameSuffix],
            '000000000' AS [policyHolder2SSN],
            '00000000' AS [policyHolder2DOB],
            '' AS [policyHolder2Sex],
            '' AS [filler_reservedforFutureUse3],
            '' AS [claimantNamePrefix],
            '' AS [claimantNameLast],
            '' AS [claimantNameFirst],
            '' AS [claimantNameMiddle],
            '' AS [claimantNameSuffix],
            '000000000' AS [claimantSSN],
            '00000000' AS [claimantDOB],
            '' AS [claimantSex],
            '' AS [claimantAddressHseNum],
            '' AS [claimantAddressStreetName],
            '' AS [claimantAddressAptNum],
            '' AS [claimantAddressCity],
            '' AS [claimantAddressState],
            '00000' AS [claimantAddressZip],
            '0000' AS [claimantAddressZipPlus4],
            '000' AS [claimantTelephoneAreaCode],
            '0000000' AS [claimantTelephoneNumber],
            '' AS [filler_reservedforFutureUse4],
            '' AS [clueControlArea],
            '' AS [filler_reservedforFutureUse5],
            '2' AS [recordVersionNumber],
            @current_date AS create_ts,
            @current_date AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE 
                WHEN (SELECT MAX(report_end_date) FROM [edw_integration].[claim_clue_property_feed]) IS NULL THEN '2020-06-29 00:00:00'
                ELSE (SELECT DATEADD(day, 1, MAX(report_end_date)) FROM [edw_integration].[claim_clue_property_feed])
            END AS [report_start_date],
            CONVERT(datetime, CONVERT(date, DATEADD(day, -1, GETDATE()))) AS [report_end_date],
            transaction_ts
        INTO [edw_temp].[claim_clue_property_feed_temp0]
        FROM claims AS c 
        INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
        LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
        LEFT JOIN edw_core.tcause_of_loss AS cof ON cof.cause_of_loss_sk = c.cause_of_loss_sk
        LEFT JOIN edw_core.tcatastrophe AS cat ON cat.catastrophe_sk=c.catastrophe_sk
        LEFT JOIN mortagee AS m ON m.policy_no = c.policy_no 
        LEFT JOIN location_address AS la ON c.policy_no = la.policy_no
        LEFT JOIN policy_insured_2 AS pi2 ON c.policy_no = pi2.policy_no
        WHERE p.product_cd IN ('HO','CO','LUX','PEL')
        ;

        --Create empty temp table to allow nulls
        SELECT TOP 0 
            B.*
        INTO [edw_temp].[claim_clue_property_feed_temp1]
        FROM [edw_temp].[claim_clue_property_feed_temp0] AS A
        LEFT JOIN [edw_temp].[claim_clue_property_feed_temp0] AS B
        ON 1=0
        ;

        --Insert all values into new table that now accepts nulls
        INSERT INTO [edw_temp].[claim_clue_property_feed_temp1]
        SELECT * FROM [edw_temp].[claim_clue_property_feed_temp0]
        ;


        ----------------------------------------------------
        --*** Start Insert rows with causeOfLoss changed ***
        ----------------------------------------------------    
        --Create temp table whit causeOfLoss that has changed in tclaim table
        SELECT 
            cp.*, cl.causeOfLoss AS new_causeOfLoss
        INTO [edw_temp].[claim_clue_property_feed_temp2]
        FROM [edw_integration].[claim_clue_property_feed] AS cp
        INNER JOIN
        (
            SELECT claimNumber, max(create_ts) as max_create_ts
            FROM [edw_integration].[claim_clue_property_feed]
            GROUP BY claimNumber
        ) AS mcp
        ON cp.claimNumber = mcp.claimNumber
        AND cp.create_ts = mcp.max_create_ts
        INNER JOIN edw_core.tclaim AS c
        ON cp.claimNumber = c.claim_no
        INNER JOIN (
                SELECT *,
                    CASE cause_of_loss_desc
                        WHEN 'Collapse' THEN 'OTHER'
                        WHEN 'Damage by Animals' THEN 'PHYDA'
                        WHEN 'Equipment Breakdown' THEN 'APPL'
                        WHEN 'Fire' THEN 'FIRE'
                        WHEN 'Flood' THEN 'FLOOD'
                        WHEN 'Freezing' THEN 'FREEZ'
                        WHEN 'Fungi/Mold' THEN 'MOLD'
                        WHEN 'Glass Breakage' THEN 'PHYDA'
                        WHEN 'Hail' THEN 'HAIL'
                        WHEN 'Hurricane' THEN 'WIND'
                        WHEN 'Ice Dam' THEN 'OTHER'
                        WHEN 'Liability' THEN 'LIAB'
                        WHEN 'Lightning' THEN 'LIGHT'
                        WHEN 'Loss Assessment' THEN 'OTHER'
                        WHEN 'Mysterious Disappearance' THEN 'DISAP'
                        WHEN 'Named Storms Other than Hurricanes' THEN 'WIND'
                        WHEN 'Power Outage' THEN 'OTHER'
                        WHEN 'Service Line' 	 THEN 'EXTEN'
                        WHEN 'Sewer and Drain' THEN 'ACCDL'
                        WHEN 'Smoke' THEN 'SMOKE'
                        WHEN 'Theft' THEN 'THEFT'
                        WHEN 'Vandalism' THEN 'VMM'
                        WHEN 'Water' THEN 'WATER'
                        WHEN 'Wind' THEN 'WIND'
                        WHEN 'Workers Compensation' THEN 'WC'
                        WHEN 'Collision' THEN 'COLL'
                        WHEN 'Other' THEN 'OTHER'
                        WHEN 'Libel, Slander, Defamation of Character' THEN 'LIAB'
                        WHEN 'Hit and Run' THEN 'COLL'
                        WHEN 'Property Damage' THEN 'DAMAG'
                        WHEN 'Fall, Slip, or Trip on Insured''s Exterior Premises' THEN 'SLIP'
                        WHEN 'Boat / Jet Ski' THEN 'CRAFT' 
                        ELSE 'OTHER'
                    END AS [causeOfLoss] 
                FROM edw_core.tcause_of_loss
            ) AS cl
        ON c.cause_of_loss_sk = cl.cause_of_loss_sk
        WHERE cp.causeOfLoss <> cl.causeOfLoss
        
        --Insert R row
        INSERT INTO [edw_temp].[claim_clue_property_feed_temp1] 
        (
            [contribCompany],
            [claimNumber],
            [causeOfLoss],
            [claimReportingStatus],
            [recordVersionNumber],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [report_start_date],
            [report_end_date]
        )
        SELECT 
            contribCompany, 
            claimNumber, 
            causeOfLoss, 
            'R' AS claimReportingStatus,
            '2' AS recordVersionNumber,
            @current_date AS create_ts,
            @current_date AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE 
                WHEN (SELECT MAX(report_end_date) FROM [edw_integration].[claim_clue_property_feed]) IS NULL THEN '2020-06-29 00:00:00'
                ELSE (SELECT DATEADD(day, 1, MAX(report_end_date)) FROM [edw_integration].[claim_clue_property_feed])
            END AS [report_start_date],
            CONVERT(datetime, CONVERT(date, DATEADD(day, -1, GETDATE()))) AS [report_end_date]
        FROM [edw_temp].[claim_clue_property_feed_temp2]

        --Insert A row if it doesn't have a transaction, but the causeOfLoss has changed
        INSERT INTO [edw_temp].[claim_clue_property_feed_temp1]
        SELECT 
            contribCompany,
            claimNumber,
            policyNumber,
            policyType,
            claimDate,
            new_causeOfLoss AS causeOfLoss,
            locationOfLoss,
            claimAmount,
            claimReportingStatus,
            claimDisposition,
            catastropheRelated,
            mortgageName,
            mortgageLoanNumber,
            filler_reservedforFutureUse,
            riskAddressHseNum,
            riskAddressStreetName,
            riskAddressAptNum,
            riskAddressCity,
            riskAddressState,
            riskAddressZip,
            riskAddressZipPlus4, 
            policyHolderMailAddrHseNum,
            policyHolderMailAddressStreetName,
            policyHolderMailAddressAptNum,
            policyHolderMailAddressCity,
            policyHolderMailAddressState,
            policyHolderMailAddressZip,
            policyHolderMailAddressZipPlus4,
            policyHolderTelAreaCode,
            policyHolderTelNumber,
            filler_reservedforFutureUse1,
            policyHolderNamePrefix,
            policyHolderNameLast,
            policyHolderNameFirst,
            policyHolderNameMiddle,
            policyHolderNameSuffix,
            policyHolderSSN,
            policyHolderDOB,
            policyHolderSex,
            filler_reservedforFutureUse2,
            policyHolder2NamePrefix,
            policyHolder2NameLast,
            policyHolder2NameFirst,
            policyHolder2NameMiddle,
            policyHolder2NameSuffix,
            policyHolder2SSN,
            policyHolder2DOB,
            policyHolder2Sex,
            filler_reservedforFutureUse3,
            claimantNamePrefix,
            claimantNameLast,
            claimantNameFirst,
            claimantNameMiddle,
            claimantNameSuffix,
            claimantSSN,
            claimantDOB,
            claimantSex,
            claimantAddressHseNum,
            claimantAddressStreetName,
            claimantAddressAptNum,
            claimantAddressCity,
            claimantAddressState,
            claimantAddressZip,
            claimantAddressZipPlus4,
            claimantTelephoneAreaCode,
            claimantTelephoneNumber,
            filler_reservedforFutureUse4,
            clueControlArea,
            filler_reservedforFutureUse5,
            recordVersionNumber,
            @current_date AS create_ts,
            @current_date AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE 
                WHEN (SELECT MAX(report_end_date) FROM [edw_integration].[claim_clue_property_feed]) IS NULL THEN '2020-06-29 00:00:00'
                ELSE (SELECT DATEADD(day, 1, MAX(report_end_date)) FROM [edw_integration].[claim_clue_property_feed])
            END AS [report_start_date],
            CONVERT(datetime, CONVERT(date, DATEADD(day, -1, GETDATE()))) AS [report_end_date],
            NULL AS transaction_ts
        FROM [edw_temp].[claim_clue_property_feed_temp2] AS t2
        WHERE NOT EXISTS (
            SELECT 1
            FROM [edw_temp].[claim_clue_property_feed_temp1] AS t1
            WHERE t1.claimNumber = t2.claimNumber AND t1.claimReportingStatus <> 'R'
        )
        ;
        ----------------------------------------------------
        --*** Start Insert rows with causeOfLoss changed ***
        ----------------------------------------------------


        -- Start Insert process
        INSERT INTO [edw_integration].[claim_clue_property_feed](
            [contribCompany],
            [claimNumber],
            [policyNumber],
            [policyType],
            [claimDate],
            [causeOfLoss],
            [locationOfLoss],
            [claimAmount],
            [claimReportingStatus],
            [claimDisposition],
            [catastropheRelated],
            [mortgageName],
            [mortgageLoanNumber],
            [filler_reservedforFutureUse],
            [riskAddressHseNum],
            [riskAddressStreetName],
            [riskAddressAptNum],
            [riskAddressCity],
            [riskAddressState],
            [riskAddressZip],
            [riskAddressZipPlus4],
            [policyHolderMailAddrHseNum],
            [policyHolderMailAddressStreetName],
            [policyHolderMailAddressAptNum],
            [policyHolderMailAddressCity],
            [policyHolderMailAddressState],
            [policyHolderMailAddressZip],
            [policyHolderMailAddressZipPlus4],
            [policyHolderTelAreaCode],
            [policyHolderTelNumber],
            [filler_reservedforFutureUse1],
            [policyHolderNamePrefix],
            [policyHolderNameLast],
            [policyHolderNameFirst],
            [policyHolderNameMiddle],
            [policyHolderNameSuffix],
            [policyHolderSSN],
            [policyHolderDOB],
            [policyHolderSex],
            [filler_reservedforFutureUse2],
            [policyHolder2NamePrefix],
            [policyHolder2NameLast],
            [policyHolder2NameFirst],
            [policyHolder2NameMiddle],
            [policyHolder2NameSuffix],
            [policyHolder2SSN],
            [policyHolder2DOB],
            [policyHolder2Sex],
            [filler_reservedforFutureUse3],
            [claimantNamePrefix],
            [claimantNameLast],
            [claimantNameFirst],
            [claimantNameMiddle],
            [claimantNameSuffix],
            [claimantSSN],
            [claimantDOB],
            [claimantSex],
            [claimantAddressHseNum],
            [claimantAddressStreetName],
            [claimantAddressAptNum],
            [claimantAddressCity],
            [claimantAddressState],
            [claimantAddressZip],
            [claimantAddressZipPlus4],
            [claimantTelephoneAreaCode],
            [claimantTelephoneNumber],
            [filler_reservedforFutureUse4],
            [clueControlArea],
            [filler_reservedforFutureUse5],
            [recordVersionNumber],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [report_start_date],
            [report_end_date]
        )
        SELECT 
            RIGHT('00000' + ISNULL([contribCompany],'0'), 5) AS [contribCompany],
            UPPER(ISNULL([claimNumber],'')) AS [claimNumber],
            UPPER(ISNULL([policyNumber],'')) AS [policyNumber],
            UPPER(ISNULL([policyType],'')) AS [policyType],
            RIGHT('00000000' + ISNULL([claimDate],'0'), 8) AS [claimDate],
            UPPER(ISNULL([causeOfLoss],'')) AS [causeOfLoss],
            UPPER(ISNULL([locationOfLoss],'')) AS [locationOfLoss],
            RIGHT('000000000' + ISNULL([claimAmount],'0'), 9) AS [claimAmount],
            UPPER(ISNULL([claimReportingStatus],'')) AS [claimReportingStatus],
            UPPER(ISNULL([claimDisposition],'')) AS [claimDisposition],
            UPPER(ISNULL([catastropheRelated],'')) AS [catastropheRelated],
            UPPER(ISNULL([mortgageName],'')) AS [mortgageName],
            UPPER(ISNULL([mortgageLoanNumber],'')) AS [mortgageLoanNumber],
            UPPER(ISNULL([filler_reservedforFutureUse],'')) AS [filler_reservedforFutureUse],
            UPPER(ISNULL([riskAddressHseNum],'')) AS [riskAddressHseNum],
            UPPER(ISNULL([riskAddressStreetName],'')) AS [riskAddressStreetName],
            UPPER(ISNULL([riskAddressAptNum],'')) AS [riskAddressAptNum],
            UPPER(ISNULL([riskAddressCity],'')) AS [riskAddressCity],
            UPPER(ISNULL([riskAddressState],'')) AS [riskAddressState],
            RIGHT('00000' + ISNULL([riskAddressZip],'0'), 5) AS [riskAddressZip],
            RIGHT('0000' + ISNULL([riskAddressZipPlus4],'0'), 4) AS [riskAddressZipPlus4],
            UPPER(ISNULL([policyHolderMailAddrHseNum],'')) AS [policyHolderMailAddrHseNum],
            UPPER(ISNULL([policyHolderMailAddressStreetName],'')) AS [policyHolderMailAddressStreetName],
            UPPER(ISNULL([policyHolderMailAddressAptNum],'')) AS [policyHolderMailAddressAptNum],
            UPPER(ISNULL([policyHolderMailAddressCity],'')) AS [policyHolderMailAddressCity],
            UPPER(ISNULL([policyHolderMailAddressState],'')) AS [policyHolderMailAddressState],
            RIGHT('00000' + ISNULL([policyHolderMailAddressZip],'0'), 5) AS [policyHolderMailAddressZip],
            RIGHT('0000' + ISNULL([policyHolderMailAddressZipPlus4],'0'), 4) AS [policyHolderMailAddressZipPlus4],
            RIGHT('000' + ISNULL([policyHolderTelAreaCode],'0'), 3) AS [policyHolderTelAreaCode],
            RIGHT('0000000' + ISNULL([policyHolderTelNumber],'0'), 7) AS [policyHolderTelNumber],
            UPPER(ISNULL([filler_reservedforFutureUse1],'')) AS [filler_reservedforFutureUse1],
            UPPER(ISNULL([policyHolderNamePrefix],'')) AS [policyHolderNamePrefix],
            UPPER(ISNULL([policyHolderNameLast],'')) AS [policyHolderNameLast],
            UPPER(ISNULL([policyHolderNameFirst],'')) AS [policyHolderNameFirst],
            UPPER(ISNULL([policyHolderNameMiddle],'')) AS [policyHolderNameMiddle],
            UPPER(ISNULL([policyHolderNameSuffix],'')) AS [policyHolderNameSuffix],
            RIGHT('000000000' + ISNULL([policyHolderSSN],'0'), 9) AS [policyHolderSSN],
            RIGHT('00000000' + ISNULL([policyHolderDOB],'0'), 8) AS [policyHolderDOB],
            UPPER(ISNULL([policyHolderSex],'')) AS [policyHolderSex],
            UPPER(ISNULL([filler_reservedforFutureUse2],'')) AS [filler_reservedforFutureUse2],
            UPPER(ISNULL([policyHolder2NamePrefix],'')) AS [policyHolder2NamePrefix],
            UPPER(ISNULL([policyHolder2NameLast],'')) AS [policyHolder2NameLast],
            UPPER(ISNULL([policyHolder2NameFirst],'')) AS [policyHolder2NameFirst],
            UPPER(ISNULL([policyHolder2NameMiddle],'')) AS [policyHolder2NameMiddle],
            UPPER(ISNULL([policyHolder2NameSuffix],'')) AS [policyHolder2NameSuffix],
            RIGHT('000000000' + ISNULL([policyHolder2SSN],'0'), 9) AS [policyHolder2SSN],
            RIGHT('00000000' + ISNULL([policyHolder2DOB],'0'), 8) AS [policyHolder2DOB],
            UPPER(ISNULL([policyHolder2Sex],'')) AS [policyHolder2Sex],
            UPPER(ISNULL([filler_reservedforFutureUse3],'')) AS [filler_reservedforFutureUse3],
            UPPER(ISNULL([claimantNamePrefix],'')) AS [claimantNamePrefix],
            UPPER(ISNULL([claimantNameLast],'')) AS [claimantNameLast],
            UPPER(ISNULL([claimantNameFirst],'')) AS [claimantNameFirst],
            UPPER(ISNULL([claimantNameMiddle],'')) AS [claimantNameMiddle],
            UPPER(ISNULL([claimantNameSuffix],'')) AS [claimantNameSuffix],
            RIGHT('000000000' + ISNULL([claimantSSN],'0'), 9) AS [claimantSSN],
            RIGHT('00000000' + ISNULL([claimantDOB],'0'), 8) AS [claimantDOB],
            UPPER(ISNULL([claimantSex],'')) AS [claimantSex],
            UPPER(ISNULL([claimantAddressHseNum],'')) AS [claimantAddressHseNum],
            UPPER(ISNULL([claimantAddressStreetName],'')) AS [claimantAddressStreetName],
            UPPER(ISNULL([claimantAddressAptNum],'')) AS [claimantAddressAptNum],
            UPPER(ISNULL([claimantAddressCity],'')) AS [claimantAddressCity],
            UPPER(ISNULL([claimantAddressState],'')) AS [claimantAddressState],
            RIGHT('00000' + ISNULL([claimantAddressZip],'0'), 5) AS [claimantAddressZip],
            RIGHT('0000' + ISNULL([claimantAddressZipPlus4],'0'), 4) AS [claimantAddressZipPlus4],
            RIGHT('000' + ISNULL([claimantTelephoneAreaCode],'0'), 3) AS [claimantTelephoneAreaCode],
            RIGHT('0000000' + ISNULL([claimantTelephoneNumber],'0'), 7) AS [claimantTelephoneNumber],
            UPPER(ISNULL([filler_reservedforFutureUse4],'')) AS [filler_reservedforFutureUse4],
            UPPER(ISNULL([clueControlArea],'')) AS [clueControlArea],
            UPPER(ISNULL([filler_reservedforFutureUse5],'')) AS [filler_reservedforFutureUse5],
            UPPER(ISNULL([recordVersionNumber],'')) AS [recordVersionNumber],
            [create_ts],
            [update_ts],
            [etl_audit_sk],
            [report_start_date],
            [report_end_date]
        FROM [edw_temp].[claim_clue_property_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_ts) FROM edw_temp.[claim_clue_property_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp0];
        DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp2];

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
