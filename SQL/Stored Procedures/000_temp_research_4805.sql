SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100064161';

SELECT pt.policy_sk, pt.effective_dt_sk, ic.internal_coverage_desc ,sum(premium_amt) as premium_amt, sum(net_premium_amt) as net_premium_amt, sum(annual_premium_amt) annual_premium_amt
FROM edw_core.tpolicy_transaction pt 
LEFT JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
WHERE pt.policy_sk = 85654
AND pt.transaction_seq_no = 4
GROUP BY pt.policy_sk, pt.effective_dt_sk, ic.internal_coverage_desc
;

