--creation of clue property table and sp
select TOP 100 * from edw_core.tetl_audit where process_nm like '%sp_claim_clue_property_feed%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_property_feed');
-- TRUNCATE TABLE [edw_integration].[claim_clue_property_feed];
-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed];
SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];
SELECT * FROM [edw_integration].[claim_clue_auto_feed];
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_property_feed');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_property_feed');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed');
-- EXEC [edw_core].[sp_claim_clue_property_feed];
-- EXEC [edw_core].[sp_claim_clue_auto_feed];
SELECT create_ts, count(1) FROM [edw_integration].[claim_clue_property_feed] group by create_ts;
-- 2024-06-24 08:23:54.710	3753
SELECT create_ts, count(1) FROM [edw_integration].[claim_clue_auto_feed] group by create_ts;
SELECT COUNT(DISTINCT CREATE_TS), COUNT(1) FROM [edw_integration].[claim_clue_auto_feed];--1,64

-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_property_feed Error Line:528 Error Message:String or binary data would be truncated in table 'vault_edw.edw_integration.claim_clue_property_feed', column 'riskAddressStreetName'. Truncated value: 'INDIGO PLANTATION RO'.

SELECT * FROM [edw_temp].[claim_clue_auto_feed_temp1] WHERE ClaimNumber = 'C21AUA00028' and ClaimType = 'CO';

SELECT count(1) FROM [edw_integration].[claim_clue_property_feed];



--Check error in data
select * 
from edw_integration.claim_clue_property_feed 
where trim(riskAddressStreetName)='' 
or trim(riskAddressState)='' 
or trim(riskAddressZip)='' 
or trim(riskAddressCity)=''
or trim(policyHolderNameFirst)='' 
or trim(policyHolderNameLast)='' 
or trim(claimReportingStatus)=''
or trim(claimAmount)='' 
or trim(causeOfLoss)='' 
or trim(policyNumber)='' 
or trim(policyType)=''
or trim(contribCompany)='' 
or trim(claimNumber)=''
or claimAmount like '%-%'
;




SELECT 
    a.claim_sk,
    a.item_sk,
    b.transaction_ts,
    SUM(a.subro_expense_paid_amt + a.subro_recovery_amt) AS sum_subro_exp_rec_amt,
    a.claim_feature_status,
    a.claim_coverage_desc,
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
    END AS [ClaimType]
FROM edw_core.tclaim_feature AS a
INNER JOIN 
    (
        SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
        FROM edw_core.tclaim_transaction
        GROUP BY claim_sk
    ) AS b ON a.claim_sk = b.claim_sk
WHERE a.source_system_sk = 3
AND a.product_sk = 3
AND a.claim_no = 'C21AUA00028'
AND claim_coverage_desc = 'Collision'
-- AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
GROUP BY
    a.claim_sk,
    a.item_sk,
    b.transaction_ts,
    a.claim_feature_status,
    a.claim_coverage_desc,
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
    ;

select * from edw_core.tauto_vehicle where auto_vehicle_sk = 7249;

SELECT *
FROM edw_core.tclaim
WHERE claim_no in ('C24HOA00030')
;
select * from 
select * from edw_core.tcause_of_loss where cause_of_loss_sk = 476;
SELECT * FROM edw_core.tclaim_transaction where claim_sk in (SELECT claim_sk FROM edw_core.tclaim WHERE claim_no in ('C24HOA00030'));

SELECT * FROM [edw_temp].[claim_clue_auto_feed_temp1] WHERE ClaimNumber = 'C24AUA00037';


SELECT * FROM vault_edw.edw_temp.claim_clue_property_feed_temp1; WHERE PolicyNumber is null;

SELECT claim_sk, COUNT(1) FROM edw_core.tclaim_transaction GROUP BY claim_sk HAVING COUNT(1) > 1;
SELECT * FROM edw_core.tclaim WHERE policy_no in ('HO200029314','HO200029316','HO200029319','HO200029320');

SELECT DISTINCT product_cd FROM edw_core.tpolicy WHERE product_cd IN ('HO','CO');

select claims_sk from edw_core.tclaim_transaction where cast(ct.transaction_ts as datetime2(7)) > @last_source_extract_ts;

SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];
SELECT * FROM [edw_integration].[claim_clue_property_feed];
SELECT * FROM [edw_integration].[claim_clue_property_feed] WHERE PolicyNumber IN ('HO200029314','HO200029316','HO200029319','HO200029320');
SELECT * FROM [edw_integration].[claim_clue_auto_feed] WHERE claimNumber IN ('C23AUA00066','C24AUA00016','C24AUA00024');
-- TRUNCATE TABLE [edw_integration].[claim_clue_property_feed];


select * from [edw_integration].[claim_clue_property_feed] where policyNumber = 'HO200027242';

-- truncate table [edw_integration].[claim_clue_property_feed];

SELECT * 
FROM [edw_integration].[claim_clue_property_feed]
WHERE CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
-- WHERE create_ts = (SELECT MAX(create_ts) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
;

SELECT MAX(CAST(create_ts AS DATE)) FROM edw_core.tpolicy;

SELECT create_ts, CAST(create_ts AS DATE) 
FROM edw_core.tpolicy
WHERE CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) FROM edw_core.tpolicy)
;

SELECT TOP 1  
        CONVERT(VARCHAR(8), report_start_date, 112) + CONVERT(VARCHAR(8), report_end_date, 112) AS start_end_date
    FROM [edw_integration].[claim_clue_property_feed]
    WHERE 1=0
    ;

-- DROP TABLE [edw_temp].[claim_clue_property_feed_temp1];
-- drop table [edw_temp].[tpolicy_hsb_cyber_feed_temp1];

select * 
FROM 
    [edw_integration].[claim_clue_property_feed]
WHERE 
    CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
    ;

SELECT TOP 1  
CONVERT(VARCHAR(8), report_start_date, 112) + CONVERT(VARCHAR(8), report_end_date, 112) AS start_end_date
FROM [edw_integration].[claim_clue_property_feed]
WHERE 
CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
;

SELECT policyHolderTelAreaCode, policyHolderTelNumber, len(policyHolderTelNumber), * FROM [edw_integration].[claim_clue_property_feed] WHERE len(policyHolderTelNumber) <> 7
;

SELECT distinct [policyHolderNamePrefix] FROM [edw_integration].[claim_clue_property_feed]
;

select * from edw_core.tproduct;

SELECT create_ts, COUNT(1) FROM [edw_integration].[claim_clue_property_feed] GROUP BY create_ts
;

SELECT policy_no, LEFT(address_line_1, 20) AS address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd FROM edw_core.tpel_location
;


SELECT 
p.mailing_address_line1,
p.mailing_address_unit_no AS [policyHolderMailAddrHseNum],
p.mailing_address_line2 AS [policyHolderMailAddressStreetName],
p.mailing_address_unit_no AS [policyHolderMailAddressAptNum],
p.mailing_address_city_nm AS [policyHolderMailAddressCity],
p.mailing_address_state_cd AS [policyHolderMailAddressState],
LEFT(p.mailing_address_zip_cd,5) AS [policyHolderMailAddressZip]
FROM edw_core.tpolicy AS p
;

select claimAmount
    ,RIGHT('000000000' + CAST(ISNULL([claimAmount],'0') AS NVARCHAR(9)), 9) AS [claimAmount]
FROM [edw_temp].[claim_clue_property_feed_temp1]
;

select top 10 * from edw_core.thome_coverage;

select distinct home_cyber_protection_coverage_limit_amt from edw_core.thome_additional_coverage;


SELECT COUNT(1)
FROM edw_core.tclaim as c
INNER JOIN 
(
    SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
    FROM edw_core.tclaim_transaction
    WHERE cast(transaction_ts as datetime2(7)) > '1900-01-01 00:00:00'
    AND cast(transaction_ts as datetime2(7)) < '2024-04-30 00:00:00'
    GROUP BY claim_sk
) AS ct ON c.claim_sk = ct.claim_sk
WHERE c.source_system_sk = 3
AND claim_no IN
            (
                'C24HOA00012',
                'C24HOA00013',
                'C24HOA00020',
                'C23HOA00102',
                'C24HOA00004',
                'C23HOA00108',
                'C23HOA00113',
                'C23HOA00111',
                'C24HOA00006',
                'C23HOA00112',
                'C23HOA00104',
                'C23HOA00109',
                'C24HOA00001',
                'C24HOA00005',
                'C24HOA00007',
                'C23HOA00105',
                'C23HOA00101',
                'C23HOA00110',
                'C24HOA00009',
                'C24HOA00010',
                'C23HOA00117',
                'C24HOA00018',
                'C24HOA00019',
                'C23HOA00106',
                'C23HOA00103',
                'C24HOA00011'
            )
;

SELECT 
    claimNumber, causeOfLoss
FROM [edw_integration].[claim_clue_property_feed]
;

SELECT ccpf.claimNumber, ccpf.causeOfLoss
FROM [edw_integration].[claim_clue_property_feed] AS ccpf
INNER JOIN 
(
    SELECT claimNumber, MAX(report_start_date) AS max_report_start_date
    FROM [edw_integration].[claim_clue_property_feed]
    GROUP BY claimNumber
) AS ccpfm
ON ccpf.claimNumber = ccpfm.claimNumber
AND ccpf.report_start_date = ccpfm.max_report_start_date
;

SELECT b.* 
FROM edw_core.tclaim_feature AS a
INNER JOIN 
    (
        SELECT claim_feature_sk, MAX(transaction_ts) AS transaction_ts
        FROM edw_core.tclaim_transaction
        GROUP BY claim_feature_sk
    ) AS b ON a.claim_feature_sk = b.claim_feature_sk
WHERE claim_no = 'C24AUA00037'
;

SELECT b.* 
FROM edw_core.tclaim_feature AS a
INNER JOIN 
    (
        SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
        FROM edw_core.tclaim_transaction
        GROUP BY claim_sk
    ) AS b ON a.claim_sk = b.claim_sk
WHERE claim_no = 'C24AUA00037'
;

SELECT * FROM [edw_integration].[claim_clue_property_feed];
SELECT * FROM [edw_integration].[claim_clue_auto_feed];
SELECT top 10 * FROM edw_core.tclaim;

-- UPDATE [edw_integration].[claim_clue_auto_feed]
-- SET create_ts = DATEADD(DAY,-1,create_ts),
-- update_ts = DATEADD(DAY,-1,update_ts),
-- report_end_date = DATEADD(DAY,-1,report_end_date)
-- ;

WITH causeOfLoss_changes AS (
    SELECT 
        cp.*, cl.causeOfLoss AS new_causeOfLoss
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
)

SELECT *
FROM causeOfLoss_changes cp
;

SELECT 
    cp.contribCompany, 
    cp.claimNumber, 
    cp.causeOfLoss, 
    'R' AS claimReportingStatus,
    '2' AS recordVersionNumber,
    cp.new_causeOfLoss
    -- a.[create_ts],
    -- a.[update_ts],
    -- a.[etl_audit_sk],
    -- a.[report_start_date],
    -- a.[report_end_date]
FROM causeOfLoss_changes cp
;

select * FROM [edw_integration].[claim_clue_property_feed] where claimNumber = 'C24HOA00030';


DECLARE @current_date DATETIME=GETDATE()
SELECT @current_date, update_ts FROM [edw_integration].[claim_clue_property_feed]
;

SELECT create_ts, count(1) FROM [edw_integration].[claim_clue_property_feed] group by create_ts;

-- DELETE FROM [edw_integration].[claim_clue_property_feed] where create_ts = '2024-06-12 21:47:52.750';

WITH claims AS (
            SELECT DISTINCT
                COALESCE(
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
            FROM edw_core.tclaim AS c
            WHERE c.source_system_sk = 3
            UNION ALL
            SELECT '0.1'
            UNION ALL
            SELECT '0.08'
)

SELECT 
    claimAmount,
    CASE 
        WHEN c.[claimAmount] < 0 THEN '-' + RIGHT('00000000' + REPLACE(CAST(ABS(c.[claimAmount]) AS VARCHAR(9)), '.', ''), 8)
        ELSE RIGHT('000000000' + REPLACE(CAST(c.[claimAmount] AS VARCHAR(10)), '.', ''), 9)
    END AS [claimAmount_without_decimal_point]
FROM claims as c
ORDER BY 1
;


SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];
SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed];



SELECT 
    mortgageName, 
    REPLACE([mortgageName], char(9), ' ') as mortgageName2,
    REPLACE(REPLACE(REPLACE([mortgageName], CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') AS cleanedColumn
FROM 
    [edw_integration].[claim_clue_property_feed]
WHERE 
    policyNumber in ('HO100100948','HO100027850-01')
        ;

SELECT 
    REPLACE(REPLACE(REPLACE([columnName], CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') AS cleanedColumn
FROM 
    [yourTableName];


SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];


--********************
--check errors
--********************

-- SELECT claimNumber, policyNumber, riskAddressStreetName, riskAddressCity, riskAddressZip FROM [edw_integration].[claim_clue_property_feed] WHERE claimNumber = 'C19HOA00002';


WITH errors_tbl AS (
    SELECT *
    FROM [edw_integration].[claim_clue_property_feed] 
    -- WHERE riskAddressStreetName = '' 
    -- OR riskAddressCity = '' 
    -- OR riskAddressZip = '00000'
    WHERE claimNumber IN
    (
        'C23HOA00273',
        'C21HOA00097',
        'C22HOA00535',
        'C22HOA00373',
        'C23HOA00367',
        'C22HOA00136'
    )
)
,location_address AS (
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

-- SELECT * FROM errors_tbl --418 Rows
SELECT policy_no, address_line_1, city_nm, zip_cd  FROM location_address WHERE policy_no in (SELECT PolicyNumber FROM errors_tbl)
-- SELECT policy_status, COUNT(1) as row_count FROM edw_core.tpolicy WHERE policy_no in (SELECT PolicyNumber FROM errors_tbl) GROUP BY policy_status
;

SELECT *--claimNumber, policyNumber, riskAddressStreetName, riskAddressCity, riskAddressZip
FROM [edw_integration].[claim_clue_property_feed]
WHERE PolicyNumber = 'EX100098978'
;



SELECT claimNumber, policyNumber, riskAddressStreetName, riskAddressCity, riskAddressZip
FROM [edw_integration].[claim_clue_property_feed] 
WHERE claimNumber IN
(
    'C23HOA00273',
    'C21HOA00097',
    'C22HOA00535',
    'C22HOA00373',
    'C23HOA00367',
    'C22HOA00136'
)
;

SELECT 
    policy_no, 
    LEFT(TRIM(SUBSTRING(address_line_1, PATINDEX('%[^0-9]%', address_line_1), 30)),20) as address_line_1, 
    address_line_2, 
    SUBSTRING(address_line_1, 1, PATINDEX('%[^0-9]%', address_line_1 + 'x') - 1) as home_no, 
    unit_no, city_nm, state_cd, zip_cd, 
    CASE WHEN LEN(zip_cd) > 5 THEN LEFT(zip_cd,5) ELSE zip_cd END AS zip_cd,
    LEFT(zip_cd,5) as zip_cd
FROM edw_core.thome_location
WHERE policy_no IN
(
    'HO100019825',
    'HO100031939',
    'HO100034599',
    'HO100167494'
)
;

SELECT * FROM [edw_temp].[claim_clue_property_feed_20240717];

SELECT * FROM edw_core.tpel_location WHERE policy_no = 'EX100098978' and primary_location_in = 'Yes';

SELECT * FROM edw_core.tproduct
;

select * from edw_integration.claim_clue_property_feed where claimAmount like '%-%'
;



WITH claims AS (
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
    and c.claim_no in ('C18HOA00001','C22HOA01149','C22HOA01150')
    -- AND cast(ct.transaction_ts as datetime2(7)) > @last_source_extract_ts
)

select
CASE 
    WHEN c.[claimAmount] < 0 THEN '000000000'
    ELSE RIGHT('000000000' + REPLACE(CAST(c.[claimAmount] AS VARCHAR(10)), '.', ''), 9)
END AS [claimAmount], *
from claims c
;

select 
policy_no
,claim_no
,COALESCE(
    (
        c.loss_paid_amt             + 
        c.expense_paid_amt          + 
        c.adjusting_other_paid_amt  + 
        c.refund_indemnity_paid_amt + 
        c.refund_expense_paid_amt
    ), 0
) AS [claimAmount]
, *
FROM edw_core.tclaim AS c
where c.claim_no in ('C18HOA00001','C22HOA01149','C22HOA01150')
;

SELECT COUNT(1) FROM [edw_temp].[claim_clue_property_feed_temp1] ;where claimAmount like '%-%';

-- select distinct policy_number,product,risk_address 
from edw_stage.OneShieldPolicy where policy_number in
(
select policynumber from edw_integration.claim_clue_property_feed where trim(riskAddressHseNum)='' and policytype!='J'
)
;


WITH AddressComponents AS (
    SELECT
        risk_address,
        PATINDEX('%[0-9]%', risk_address) AS StreetNumberStart,
        PATINDEX('% [^0-9]%', risk_address) AS StreetNumberEnd,
        CHARINDEX(' ', risk_address, PATINDEX('% [^0-9]%', risk_address) + 1) AS StreetNameEnd,
        LEN(risk_address) - CHARINDEX(' ', REVERSE(risk_address)) + 1 AS ZipStart
    from edw_stage.OneShieldPolicy where policy_number in
        (
        select policynumber from edw_integration.claim_clue_property_feed where trim(riskAddressHseNum)='' and policytype!='J'
        )
)
SELECT
    risk_address,
    CASE
        WHEN StreetNumberStart > 0 AND StreetNumberEnd > 0 AND StreetNumberEnd > StreetNumberStart
            THEN SUBSTRING(risk_address, StreetNumberStart, StreetNumberEnd - StreetNumberStart)
        ELSE ''
    END AS StreetNumber,
    CASE
        WHEN StreetNumberEnd > 0 AND StreetNameEnd > 0 AND StreetNameEnd > StreetNumberEnd
            THEN SUBSTRING(risk_address, StreetNumberEnd + 1, StreetNameEnd - StreetNumberEnd - 1)
        ELSE ''
    END AS StreetName,
    CASE
        WHEN StreetNameEnd > 0 AND ZipStart > StreetNameEnd
            THEN SUBSTRING(risk_address, StreetNameEnd + 1, ZipStart - StreetNameEnd - 1)
        ELSE ''
    END AS CityState,
    CASE
        WHEN ZipStart > 0 AND ZipStart <= LEN(risk_address)
            THEN SUBSTRING(risk_address, ZipStart, LEN(risk_address) - ZipStart + 1)
        ELSE ''
    END AS ZipCode
FROM 
    AddressComponents
    ;

SELECT 
claimNumber, PolicyNumber,
riskAddressHseNum, riskAddressStreetName, riskAddressAptNum, riskAddressCity, riskAddressState, riskAddressZip
FROM [edw_integration].[claim_clue_property_feed] 
WHERE PolicyNumber IN ('HO100019825','HO100167494');


