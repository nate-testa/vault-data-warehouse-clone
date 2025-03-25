--creation of clue property table and sp
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_auto_feed');
select * from edw_core.tetl_audit where process_nm like '%sp_claim_clue_auto_feed%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed');
-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed];
SELECT * FROM [edw_integration].[claim_clue_auto_feed];
-- EXEC [edw_core].[sp_claim_clue_auto_feed];

-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:282 Error Message:Violation of UNIQUE KEY constraint 'uidx_claim_clue_auto_feed'. Cannot insert duplicate key in object 'edw_integration.claim_clue_auto_feed'. The duplicate key value is (C21AUA00028         , CO, Jun 29 2020 12:00AM).
-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:287 Error Message:Violation of UNIQUE KEY constraint 'uidx_claim_clue_auto_feed'. Cannot insert duplicate key in object 'edw_integration.claim_clue_auto_feed'. The duplicate key value is (C21AUA00028         , CO, Jun 29 2020 12:00AM).
-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:283 Error Message:Violation of UNIQUE KEY constraint 'uidx_claim_clue_auto_feed'. Cannot insert duplicate key in object 'edw_integration.claim_clue_auto_feed'. The duplicate key value is (C21AUA00028         , CO, Jun 29 2020 12:00AM).

SELECT ClaimNumber, ClaimType, COUNT(1) AS CANT, COUNT(DISTINCT(InsuredVehicleVIN)) AS COUNT_DISTINCT_VIN FROM [edw_temp].[claim_clue_auto_feed_temp1] GROUP BY ClaimNumber, ClaimType HAVING COUNT(1) > 1;
SELECT * FROM [edw_temp].[claim_clue_auto_feed_temp1] WHERE ClaimNumber = 'C22AUA01311' AND claimType = 'PD';

SELECT item_sk, * FROM edw_core.tclaim_feature
WHERE source_system_sk = 3
AND product_sk = 3
AND Claim_no IN ('C23AUA00323','C22AUA01311');


SELECT create_ts, COUNT(1)
FROM [edw_integration].[claim_clue_auto_feed]
GROUP BY create_ts
-- 2024-06-05 06:50:17.133	68
-- 2024-06-06 08:44:36.537	4
-- 2024-06-07 05:52:44.927	5
;

SELECT *
FROM [edw_integration].[claim_clue_auto_feed]
    WHERE 
        CAST(create_ts AS DATE) = '2024-06-05 06:50:17.133'
        ;


SELECT * FROM [edw_temp].[claim_clue_auto_feed_temp1] WHERE claimNumber = 'C21AUA00136';
SELECT * FROM [edw_integration].[claim_clue_auto_feed] WHERE claimNumber = 'C21AUA00136';
SELECT UPPER(policy_no) FROM edw_core.tauto_driver where policy_no = 'AU100039191';

SELECT DISTINCT product_cd FROM edw_core.tpolicy; WHERE product_cd IN ('HO','CO');

select claims_sk from edw_core.tclaim_transaction where cast(ct.transaction_ts as datetime2(7)) > @last_source_extract_ts;

SELECT * FROM edw_core.tclaim WHERE claim_no = 'C21AUA00147';
SELECT * FROM edw_core.tclaim_feature WHERE claim_sk = 304;

SELECT * FROM edw_core.tcustomer;
SELECT * FROM edw_core.tpolicy_insured;
SELECT top 10 license_no, license_state_nm, gender, * FROM edw_core.tauto_driver;
SELECT * FROM edw_core.tauto_vehicle;
SELECT * FROM edw_core.tclaim;
SELECT * FROM edw_core.tclaim_feature WHERE product_sk = 3;
SELECT * FROM edw_core.tcustomer;
SELECT DISTINCT gender FROM edw_core.tauto_driver;
SELECT * FROM edw_core.tclaim_transaction;



-------------------------------------
SELECT 
    subro_expense_paid_amt, 
    subro_recovery_amt, 
    claim_feature_status,
    CASE 
        WHEN (subro_expense_paid_amt + subro_recovery_amt) < 0 THEN 'S'
        WHEN claim_feature_status ='CLOSED' THEN 'C' 
        ELSE 'O' 
    END AS [claimDisposition]
FROM edw_core.tclaim_feature
WHERE claim_no = 'C24AUA00024'
;

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
        SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
        FROM edw_core.tclaim_transaction
        GROUP BY claim_sk
    ) AS b ON a.claim_sk = b.claim_sk
WHERE a.source_system_sk = 3
AND a.product_sk = 3
AND A.claim_no = 'C24AUA00024'
-- AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
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
;


SELECT claim_feature_sk, MAX(transaction_ts) AS transaction_ts, count(1)
FROM edw_core.tclaim_transaction
GROUP BY claim_feature_sk
;

SELECT * FROM [edw_integration].[claim_clue_auto_feed] 
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


WITH claim_feature AS (
    SELECT 
        a.claim_sk,
        a.item_sk,
        b.transaction_ts,
        SUM(a.subro_expense_paid_amt + a.subro_recovery_amt) AS sum_subro_exp_rec_amt,
        MAX(
            CASE 
                WHEN a.claim_feature_status = 'CLOSED' THEN 1
                ELSE 2
            END
        )
        AS claim_feature_status_no,
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
            SELECT claim_sk, MAX(transaction_ts) AS transaction_ts
            FROM edw_core.tclaim_transaction
            GROUP BY claim_sk
        ) AS b ON a.claim_sk = b.claim_sk
    WHERE a.source_system_sk = 3
    AND a.product_sk = 3
    -- AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
    GROUP BY
        a.claim_sk,
        a.item_sk,
        b.transaction_ts,
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

SELECT * FROM claim_feature WHERE claim_sk = '6236'
;

SELECT * FROM edw_core.tclaim where claim_no = 'C23AUA00323'
;

--     C23AUA00323	CO	2	1
-- C22AUA01311	PD	2	1

SELECT * FROM [edw_temp].[claim_clue_auto_feed_20240717];