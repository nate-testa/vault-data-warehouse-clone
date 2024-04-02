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
		DROP TABLE IF EXISTS [edw_temp].[claim_clue_property_feed_temp1];

        WITH 
        location_address AS (
            SELECT policy_no, LEFT(address_line_1, 20) AS address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd FROM edw_core.tpel_location
                UNION
            SELECT policy_no, LEFT(address_line_1, 20) AS address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd FROM edw_core.thome_location
                UNION
            SELECT policy_no, LEFT(address_line_1, 20) AS address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd FROM edw_core.tcollection_location
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
                ELSE ' ' 
            END AS [contribCompany],
            c.claim_no AS [claimNumber],
            p.policy_no AS [policyNumber],
            CASE 
                WHEN p.product_cd IN ('HO','CO') THEN 'H'
                WHEN p.product_cd = 'LUX' THEN 'I'
                WHEN p.product_cd = 'PEL' THEN 'J'
                ELSE ''
            END AS [policyType],
            FORMAT(c.loss_dt, 'MMddyyyy') AS [claimDate],
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
            CAST(c.[claimAmount] AS INT) AS [claimAmount],
            'A' AS [claimReportingStatus],
            c.[claimDisposition],
            CASE WHEN cat.catastrophe_nm  IS NULL THEN 'N' ELSE 'Y' END AS [catastropheRelated],
            m.mortgagee_nm AS [mortgageName],
            m.loan_no  AS [mortgageLoanNumber],
            '' AS [filler_reservedforFutureUse],
            la.unit_no AS [riskAddressHseNum],
            la.address_line_1 AS [riskAddressStreetName],
            la.unit_no AS [riskAddressAptNum],
            la.city_nm AS [riskAddressCity],
            la.state_cd AS [riskAddressState],
            la.zip_cd AS [riskAddressZip],
            '' AS [riskAddressZipPlus4],
            p.mailing_address_unit_no AS [policyHolderMailAddrHseNum],
            p.mailing_address_line2 AS [policyHolderMailAddressStreetName],
            p.mailing_address_unit_no AS [policyHolderMailAddressAptNum],
            p.mailing_address_city_nm AS [policyHolderMailAddressCity],
            p.mailing_address_state_cd AS [policyHolderMailAddressState],
            LEFT(p.mailing_address_zip_cd,5) AS [policyHolderMailAddressZip],
            '' AS [policyHolderMailAddressZipPlus4],
            SUBSTRING(cu.home_phone_no,1,3) AS [policyHolderTelAreaCode],
            SUBSTRING(cu.home_phone_no,4,7) AS [policyHolderTelNumber],
            '' AS [filler_reservedforFutureUse1],
            '' AS [policyHolderNamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.last_nm ELSE cu.customer_nm END AS [policyHolderNameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN cu.first_nm ELSE cu.customer_nm END AS [policyHolderNameFirst],
            '' AS [policyHolderNameMiddle],
            '' AS [policyHolderNameSuffix],
            '' AS [policyHolderSSN],
            FORMAT(cu.birth_dt, 'MMddyyyy') AS [policyHolderDOB],
            '' AS [policyHolderSex],
            '' AS [filler_reservedforFutureUse2],
            '' AS [policyHolder2NamePrefix],
            CASE WHEN cu.insured_type = 'Individual' THEN pi2.last_nm ELSE pi2.insured_nm END AS [policyHolder2NameLast],
            CASE WHEN cu.insured_type = 'Individual' THEN pi2.first_nm ELSE pi2.insured_nm END AS [policyHolder2NameFirst],
            '' AS [policyHolder2NameMiddle],
            '' AS [policyHolder2NameSuffix],
            '' AS [policyHolder2SSN],
            '' AS [policyHolder2DOB],
            '' AS [policyHolder2Sex],
            '' AS [filler_reservedforFutureUse3],
            '' AS [claimantNamePrefix],
            '' AS [claimantNameLast],
            '' AS [claimantNameFirst],
            '' AS [claimantNameMiddle],
            '' AS [claimantNameSuffix],
            '' AS [claimantSSN],
            '' AS [claimantDOB],
            '' AS [claimantSex],
            '' AS [claimantAddressHseNum],
            '' AS [claimantAddressStreetName],
            '' AS [claimantAddressAptNum],
            '' AS [claimantAddressCity],
            '' AS [claimantAddressState],
            '' AS [claimantAddressZip],
            '' AS [claimantAddressZipPlus4],
            '' AS [claimantTelephoneAreaCode],
            '' AS [claimantTelephoneNumber],
            '' AS [filler_reservedforFutureUse4],
            '' AS [clueControlArea],
            '' AS [filler_reservedforFutureUse5],
            '' AS [recordVersionNumber],
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            CASE 
                WHEN (SELECT MAX(report_end_date) FROM [edw_integration].[claim_clue_property_feed]) IS NULL THEN '2020-06-29 00:00:00'
                ELSE (SELECT DATEADD(day, 1, MAX(report_end_date)) FROM [edw_integration].[claim_clue_property_feed])
            END AS [report_start_date],
            CONVERT(datetime, CONVERT(date, DATEADD(day, -1, GETDATE()))) AS [report_end_date],
            transaction_ts
        INTO [edw_temp].[claim_clue_property_feed_temp1] 
        FROM claims AS c 
        INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
        LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
        LEFT JOIN edw_core.tcause_of_loss AS cof ON cof.cause_of_loss_sk = c.cause_of_loss_sk
        LEFT JOIN edw_core.tcatastrophe AS cat ON cat.catastrophe_sk=c.catastrophe_sk
        LEFT JOIN mortagee AS m ON m.policy_no = c.policy_no 
        LEFT JOIN location_address AS la ON c.policy_no = la.policy_no
        LEFT JOIN policy_insured_2 AS pi2 ON c.policy_no = pi2.policy_no
        WHERE p.product_cd IN ('HO','CO')
        ;

        
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
            ISNULL([contribCompany],'') AS [contribCompany],
            ISNULL([claimNumber],'') AS [claimNumber],
            ISNULL([policyNumber],'') AS [policyNumber],
            ISNULL([policyType],'') AS [policyType],
            ISNULL([claimDate],'') AS [claimDate],
            ISNULL([causeOfLoss],'') AS [causeOfLoss],
            ISNULL([locationOfLoss],'') AS [locationOfLoss],
            ISNULL([claimAmount],'') AS [claimAmount],
            ISNULL([claimReportingStatus],'') AS [claimReportingStatus],
            ISNULL([claimDisposition],'') AS [claimDisposition],
            ISNULL([catastropheRelated],'') AS [catastropheRelated],
            ISNULL([mortgageName],'') AS [mortgageName],
            ISNULL([mortgageLoanNumber],'') AS [mortgageLoanNumber],
            ISNULL([filler_reservedforFutureUse],'') AS [filler_reservedforFutureUse],
            ISNULL([riskAddressHseNum],'') AS [riskAddressHseNum],
            ISNULL([riskAddressStreetName],'') AS [riskAddressStreetName],
            ISNULL([riskAddressAptNum],'') AS [riskAddressAptNum],
            ISNULL([riskAddressCity],'') AS [riskAddressCity],
            ISNULL([riskAddressState],'') AS [riskAddressState],
            ISNULL([riskAddressZip],'') AS [riskAddressZip],
            ISNULL([riskAddressZipPlus4],'') AS [riskAddressZipPlus4],
            ISNULL([policyHolderMailAddrHseNum],'') AS [policyHolderMailAddrHseNum],
            ISNULL([policyHolderMailAddressStreetName],'') AS [policyHolderMailAddressStreetName],
            ISNULL([policyHolderMailAddressAptNum],'') AS [policyHolderMailAddressAptNum],
            ISNULL([policyHolderMailAddressCity],'') AS [policyHolderMailAddressCity],
            ISNULL([policyHolderMailAddressState],'') AS [policyHolderMailAddressState],
            ISNULL([policyHolderMailAddressZip],'') AS [policyHolderMailAddressZip],
            ISNULL([policyHolderMailAddressZipPlus4],'') AS [policyHolderMailAddressZipPlus4],
            ISNULL([policyHolderTelAreaCode],'') AS [policyHolderTelAreaCode],
            ISNULL([policyHolderTelNumber],'') AS [policyHolderTelNumber],
            ISNULL([filler_reservedforFutureUse1],'') AS [filler_reservedforFutureUse1],
            ISNULL([policyHolderNamePrefix],'') AS [policyHolderNamePrefix],
            ISNULL([policyHolderNameLast],'') AS [policyHolderNameLast],
            ISNULL([policyHolderNameFirst],'') AS [policyHolderNameFirst],
            ISNULL([policyHolderNameMiddle],'') AS [policyHolderNameMiddle],
            ISNULL([policyHolderNameSuffix],'') AS [policyHolderNameSuffix],
            ISNULL([policyHolderSSN],'') AS [policyHolderSSN],
            ISNULL([policyHolderDOB],'') AS [policyHolderDOB],
            ISNULL([policyHolderSex],'') AS [policyHolderSex],
            ISNULL([filler_reservedforFutureUse2],'') AS [filler_reservedforFutureUse2],
            ISNULL([policyHolder2NamePrefix],'') AS [policyHolder2NamePrefix],
            ISNULL([policyHolder2NameLast],'') AS [policyHolder2NameLast],
            ISNULL([policyHolder2NameFirst],'') AS [policyHolder2NameFirst],
            ISNULL([policyHolder2NameMiddle],'') AS [policyHolder2NameMiddle],
            ISNULL([policyHolder2NameSuffix],'') AS [policyHolder2NameSuffix],
            ISNULL([policyHolder2SSN],'') AS [policyHolder2SSN],
            ISNULL([policyHolder2DOB],'') AS [policyHolder2DOB],
            ISNULL([policyHolder2Sex],'') AS [policyHolder2Sex],
            ISNULL([filler_reservedforFutureUse3],'') AS [filler_reservedforFutureUse3],
            ISNULL([claimantNamePrefix],'') AS [claimantNamePrefix],
            ISNULL([claimantNameLast],'') AS [claimantNameLast],
            ISNULL([claimantNameFirst],'') AS [claimantNameFirst],
            ISNULL([claimantNameMiddle],'') AS [claimantNameMiddle],
            ISNULL([claimantNameSuffix],'') AS [claimantNameSuffix],
            ISNULL([claimantSSN],'') AS [claimantSSN],
            ISNULL([claimantDOB],'') AS [claimantDOB],
            ISNULL([claimantSex],'') AS [claimantSex],
            ISNULL([claimantAddressHseNum],'') AS [claimantAddressHseNum],
            ISNULL([claimantAddressStreetName],'') AS [claimantAddressStreetName],
            ISNULL([claimantAddressAptNum],'') AS [claimantAddressAptNum],
            ISNULL([claimantAddressCity],'') AS [claimantAddressCity],
            ISNULL([claimantAddressState],'') AS [claimantAddressState],
            ISNULL([claimantAddressZip],'') AS [claimantAddressZip],
            ISNULL([claimantAddressZipPlus4],'') AS [claimantAddressZipPlus4],
            ISNULL([claimantTelephoneAreaCode],'') AS [claimantTelephoneAreaCode],
            ISNULL([claimantTelephoneNumber],'') AS [claimantTelephoneNumber],
            ISNULL([filler_reservedforFutureUse4],'') AS [filler_reservedforFutureUse4],
            ISNULL([clueControlArea],'') AS [clueControlArea],
            ISNULL([filler_reservedforFutureUse5],'') AS [filler_reservedforFutureUse5],
            ISNULL([recordVersionNumber],'') AS [recordVersionNumber],
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
        DROP TABLE IF EXISTS edw_temp.[claim_clue_property_feed_temp1];

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
