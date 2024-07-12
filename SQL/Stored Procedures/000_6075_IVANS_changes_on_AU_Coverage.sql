select * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;

select * from [edw_temp].[policy_ivans_auto_feed_temp1];
select * from [edw_temp].[policy_ivans_auto_feed_temp2];

SELECT *
FROM [edw_temp].[policy_ivans_auto_feed_temp2] AS pt
INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
INNER JOIN edw_core.tbroker AS b ON p.broker_id = b.broker_id
WHERE b.ivans_y_account IS NOT NULL
;


--policy_ivans_auto_feed
select count(1) from [edw_integration].[policy_ivans_auto_feed];
select * from [edw_integration].[policy_ivans_auto_feed] where PolicyNumber_031 = 'AU200023774';
update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_policy_ivans_auto_feed');
truncate table [edw_integration].[policy_ivans_auto_feed];
EXEC [edw_core].[sp_policy_ivans_auto_feed];

SELECT TOP 10 * 
FROM [edw_integration].[policy_ivans_auto_feed]
;

select * from edw_core.tpolicy_transaction
where policy_sk = 1377;
and coverage_sk = 22523
and internal_coverage_sk = 742
-- and item_sk = 34473
;

SELECT * FROM edw_core.tpolicy where policy_no = 'AU200023774';

SELECT 
    pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk,
    SUM(pt.annual_premium_amt) AS annual_premium_amt, 
    SUM(pt.premium_amt) AS premium_amt , count(1), 
    (
        SELECT SUM(subpt.annual_premium_amt)
        FROM edw_core.tpolicy_transaction subpt 
        WHERE subpt.policy_sk = pt.policy_sk
        AND subpt.effective_dt_sk = pt.effective_dt_sk
        AND subpt.internal_coverage_sk = pt.internal_coverage_sk
        AND subpt.transaction_seq_no <= pt.transaction_seq_no
    ) as annual_premium_amt_2
FROM edw_core.tpolicy_transaction as pt
INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
INNER JOIN edw_core.tpolicy_history as ph 
ON pt.policy_sk = ph.policy_sk
AND pt.transaction_seq_no = ph.transaction_seq_no
WHERE 1=1
    AND pr.product_cd = 'AU'
-- AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
AND pt.policy_sk = 45735
-- and 
GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk
-- HAVING COUNT(1) > 4
ORDER BY internal_coverage_sk, transaction_seq_no
;

SELECT TOP 100 vehicle_coverage_sk, coverage_sk FROM edw_core.tpolicy_transaction;

-----------PEL----------------
SELECT * FROM edw_core.tpolicy WHERE policy_no = 'EX100034953-03';
SELECT * FROM edw_core.tcoverage


----
SELECT 
    pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk, ic.internal_coverage_cd AS coverageCd,
    SUM(pt.annual_premium_amt) as annual_premium_amt_OLD,
    (
        SELECT SUM(subpt.annual_premium_amt)
        FROM edw_core.tpolicy_transaction subpt 
        WHERE subpt.policy_sk = pt.policy_sk
        AND subpt.effective_dt_sk = pt.effective_dt_sk
        AND subpt.internal_coverage_sk = pt.internal_coverage_sk
        AND subpt.transaction_seq_no <= pt.transaction_seq_no
    ) as annual_premium_amt_NEW,
    SUM(pt.premium_amt) AS premium_amt 
FROM (select * from edw_core.tpolicy_transaction where policy_sk in (SELECT policy_sk FROM edw_core.tpolicy WHERE policy_no = 'EX100034953-03')) as pt
INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
INNER JOIN edw_core.tpolicy_history as ph 
ON pt.policy_sk = ph.policy_sk
AND pt.transaction_seq_no = ph.transaction_seq_no
INNER JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
WHERE 1=1
    AND pr.product_cd = 'PEL'
-- AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk, ic.internal_coverage_cd
ORDER BY pt.internal_coverage_sk, pt.transaction_seq_no
;

