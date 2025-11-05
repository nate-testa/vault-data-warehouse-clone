SELECT TOP 10 * FROM edw_core.tpolicy_transaction;
SELECT COUNT(1) CT FROM edw_core.tpolicy_transaction where ceded_premium_amt <> 0 or ceded_annual_premium_amt <> 0;
SELECT COUNT(1) FROM edw_temp.tpolicy_transaction_hist_upd where ceded_premium_amt <> 0 or ceded_annual_premium_amt <> 0;

SELECT policy_sk, effective_dt_sk, transaction_seq_no, internal_coverage_sk, vehicle_coverage_sk
,COUNT(1) ct
FROM edw_core.tpolicy_transaction
GROUP BY policy_sk, effective_dt_sk, transaction_seq_no, internal_coverage_sk, vehicle_coverage_sk
HAVING COUNT(1) > 1
;

SELECT TOP 10 * 
FROM edw_core.tpolicy_transaction
where policy_sk = 45819
and effective_dt_sk = 2344
and transaction_seq_no = 2
and internal_coverage_sk = 312
and vehicle_coverage_sk = 233700
;

select  top 10
    a.ceded_premium_amt as ceded_premium_amt_a,
    b.ceded_premium_amt as ceded_premium_amt_b,
    a.ceded_annual_premium_amt as ceded_annual_premium_amt_a,
    b.ceded_annual_premium_amt as ceded_annual_premium_amt_b
from edw_core.tpolicy_transaction a
inner join edw_temp.tpolicy_transaction_hist_upd b
on a.policy_sk = b.policy_sk
and a.effective_dt_sk = b.effective_dt_sk
and a.transaction_seq_no = b.transaction_seq_no
and a.internal_coverage_sk = b.internal_coverage_sk
WHERE (a.ceded_premium_amt <> b.ceded_premium_amt OR a.ceded_annual_premium_amt <> b.ceded_annual_premium_amt)
;

/*
UPDATE a
SET 
    a.ceded_premium_amt = b.ceded_premium_amt,
    a.ceded_annual_premium_amt = b.ceded_annual_premium_amt
FROM edw_core.tpolicy_transaction a
INNER JOIN edw_temp.tpolicy_transaction_hist_upd b
    ON a.policy_sk = b.policy_sk
    AND a.effective_dt_sk = b.effective_dt_sk
    AND a.transaction_seq_no = b.transaction_seq_no
    AND a.internal_coverage_sk = b.internal_coverage_sk
WHERE (a.ceded_premium_amt <> b.ceded_premium_amt OR a.ceded_annual_premium_amt <> b.ceded_annual_premium_amt)
;
*/
