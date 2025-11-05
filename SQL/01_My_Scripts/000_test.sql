select * from edw_core.tclaim where claim_no = 'C20AUA00002';

with 
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
,claims AS (
            SELECT 
                c.claim_sk
                ,c.claim_no
                ,c.policy_sk
                ,c.policy_no
                ,c.cause_of_loss_sk
                ,c.catastrophe_sk
                ,c.loss_dt
                ,c.product_sk
                ,c.fault_decision
                ,c.loss_state_cd
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
            WHEN claim_coverage_desc = 'PIP' THEN 'PI'
            WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
            WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
            WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UM'
            WHEN claim_coverage_desc = 'Underinsured Motorist Liablity' THEN 'UN'
            ELSE 'OT'
        END AS [ClaimType],
        SUM(
            COALESCE(
                    (
                        a.loss_paid_amt                     +
                        a.subrogation_recovery_amt          +
                        a.overpayment_recovery_amt          
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
    AND a.claim_sk = 978
    -- AND (
    --         cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
    --         OR
    --         a.claim_sk IN (select claim_sk from [edw_temp].[claim_clue_auto_feed_temp3])
    -- )
    GROUP BY
        a.claim_sk,
        b.transaction_ts,
        CASE
            WHEN claim_coverage_desc = 'Combined Single Limits' THEN 'BI'
            WHEN claim_coverage_desc = 'Collision' THEN 'CO'
            WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
            WHEN claim_coverage_desc = 'Full Glass' THEN 'GL'
            WHEN claim_coverage_desc = 'Medical Payments' THEN 'MP'
            WHEN claim_coverage_desc = 'PIP' THEN 'PI'
            WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
            WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
            WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UM'
            WHEN claim_coverage_desc = 'Underinsured Motorist Liablity' THEN 'UN'
            ELSE 'OT'
        END
)

SELECT 
cu.insured_type,
CASE 
    WHEN cu.insured_type = 'Individual' THEN cu.last_nm 
    WHEN cu.insured_type = 'Entity' THEN cu.customer_nm
END AS [PolicyHolderNameLast],
CASE 
    WHEN cu.insured_type = 'Individual' THEN cu.first_nm 
    WHEN cu.insured_type = 'Entity' THEN 'DBA'
END AS [PolicyHolderNameFirst],
CASE 
    WHEN cu.insured_type = 'Individual' THEN cu.middle_nm 
    WHEN cu.insured_type = 'Entity' THEN NULL
END AS [PolicyHolderNameMiddle]
FROM claim_feature AS cf
INNER JOIN claims AS c ON cf.claim_sk = c.claim_sk
INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
LEFT JOIN edw_stage.OneShieldPolicy_clue AS osp ON c.policy_no = osp.policy_no
LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
;

select * from edw_core.tclaim where claim_no = 'C20AUA00002';
select * from edw_core.tpolicy where policy_sk = 154105;
select insured_type, count(1) rc from edw_core.tpolicy group by insured_type;

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