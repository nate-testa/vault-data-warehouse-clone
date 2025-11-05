select * from edw_core.tetl_audit where process_nm='sp_claim_clue_property_feed'
order by 1 desc
;

SELECT create_ts, COUNT(1) FROM [edw_integration].[claim_clue_property_feed] GROUP BY create_ts ORDER BY create_ts;

SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed] WHERE CAST(create_ts AS DATE) <> CAST(GETDATE() AS DATE)
;

select claimNumber,count(*) from edw_integration.claim_clue_property_feed where cast(create_ts as date)='20250208'
group by claimNumber
having count(*)>1
;

select create_ts, causeOfLoss, * from edw_integration.claim_clue_property_feed where claimNumber = 'C24HOA00259' order by 1
;

select edw_core.fn_get_last_source_extract_ts('sp_claim_clue_property_feed');



SELECT causeOfLoss, * FROM [edw_temp].[claim_clue_property_feed_temp0];
SELECT * FROM [edw_temp].[claim_clue_property_feed_temp2];
SELECT * FROM [edw_temp].[claim_clue_property_feed_temp1];

SELECT claimReportingStatus, COUNT(1) AS CT FROM [edw_temp].[claim_clue_property_feed_temp1] GROUP BY claimReportingStatus;

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
                        c.defense_paid_amt
                    ), 0
                ) AS [claimAmount]
                ,CASE 
                    WHEN (c.subrogation_expense_recovery_amt + c.subrogation_recovery_amt) < 0 THEN 'S'
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
            AND cast(ct.transaction_ts as datetime2(7)) > '2025-02-07 05:40:10'
            -- AND c.claim_no = 'C24HOA00259'
        )
SELECT *
FROM claims AS c 
-- INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
-- LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
-- LEFT JOIN edw_core.tcause_of_loss AS cof ON cof.cause_of_loss_sk = c.cause_of_loss_sk
-- LEFT JOIN edw_core.tcatastrophe AS cat ON cat.catastrophe_sk=c.catastrophe_sk
-- LEFT JOIN mortagee AS m ON m.policy_no = c.policy_no AND m.rn = 1
-- INNER JOIN location_address AS la ON c.policy_no = la.policy_no
-- LEFT JOIN policy_insured_2 AS pi2 ON c.policy_no = pi2.policy_no
-- WHERE p.product_cd IN ('HO','CO','LUX')
;