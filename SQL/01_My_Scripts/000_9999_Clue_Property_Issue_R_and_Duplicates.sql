select top 100 * from edw_core.tetl_audit where process_nm like '%hsb%' order by etl_audit_sk desc;
select * from edw_core.tetl_control where process_nm like '%sp_claim_clue_property_feed%';
select * from edw_core.tedw_table_detail where table_nm like '%ivans%';

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_claim_clue_property_feed';
-- TRUNCATE TABLE [edw_integration].[claim_clue_property_feed];
-- EXEC [edw_core].[sp_claim_clue_property_feed];
SELECT count(1) FROM [edw_integration].[claim_clue_property_feed];



select claimNumber, claimAmount, claimReportingStatus, create_ts, causeOfLoss
from edw_integration.claim_clue_property_feed 
where claimNumber='C19HOA00007'
order by create_ts DESC
;

SELECT * FROM edw_core.tclaim WHERE claim_no = 'C19HOA00007';

SELECT transaction_ts, * FROM edw_core.tclaim_transaction WHERE claim_sk = 975;

SELECT *
FROM [edw_integration].[claim_clue_property_feed]
WHERE claimNumber = 'C21HOA00015'
ORDER BY create_ts DESC
;



SELECT claimNumber, causeOfLoss, claimReportingStatus, create_ts
FROM [edw_integration].[claim_clue_property_feed]
;


--********************************* Issue with claimReportingStatus R ******************************************
WITH
transactions_by_claim AS (
    SELECT c.claimNumber, c.claimReportingStatus, c.create_ts, c.causeOfLoss, 
        ROW_NUMBER() OVER (PARTITION BY c.claimNumber ORDER BY c.create_ts DESC, c.claimReportingStatus ASC) AS rn
    FROM [edw_integration].[claim_clue_property_feed] AS c
)
,last_a_status_by_claim AS (
    SELECT c.claimNumber, c.claimReportingStatus, c.create_ts, c.causeOfLoss, 
        ROW_NUMBER() OVER (PARTITION BY c.claimNumber ORDER BY c.create_ts DESC) AS rn
    FROM [edw_integration].[claim_clue_property_feed] AS c
    WHERE c.claimReportingStatus = 'A'
    AND c.claimNumber IN (SELECT claimNumber FROM transactions_by_claim WHERE rn = 1 AND claimReportingStatus = 'R')
)

-- *** List claims with their last movement in R (Removed)
SELECT * FROM transactions_by_claim WHERE rn = 1 AND claimReportingStatus = 'R'

-- *** List claims with last movement in A
-- SELECT * FROM last_a_status_by_claim WHERE rn = 1

-- *** Rows to create (with last A Status before being removed)
-- SELECT DISTINCT cp.* 
-- FROM [edw_integration].[claim_clue_property_feed] AS cp 
-- INNER JOIN last_a_status_by_claim AS lsc 
--     ON cp.claimNumber = lsc.claimNumber 
--     AND cp.claimReportingStatus = lsc.claimReportingStatus 
--     AND cp.create_ts = lsc.create_ts 
--     AND cp.causeOfLoss = lsc.causeOfLoss
-- WHERE lsc.claimNumber IN (SELECT claimNumber FROM transactions_by_claim WHERE rn = 1 AND claimReportingStatus = 'R')
-- AND lsc.rn = 1
;
--********************************* Issue with claimReportingStatus R ******************************************

select distinct claimNumber from edw_integration.claim_clue_property_feed where claimReportingStatus = 'R';


select * from edw_temp.claim_clue_property_feed_20241010;

-- update edw_temp.claim_clue_property_feed_20241010 set report_start_date = '2024-10-09 00:00:00.000', report_end_date = '2024-10-09 00:00:00.000';

-- update edw_temp.claim_clue_property_feed_20241010 set create_ts = '2024-10-10 01:00:00.000', update_ts = '2024-10-10 01:00:00.000';


SELECT create_ts,
        CAST(create_ts AS DATE) as onlydate,
       count(1)
FROM 
    [edw_integration].[claim_clue_property_feed]
WHERE   
    CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
group by create_ts, CAST(create_ts AS DATE)
;
-- 2024-10-11 00:00:00.000	2024-10-11	55


-- ********** Duplicates by claimReportingStatus A ************

SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];

SELECT 
    c.claimNumber, c.claimReportingStatus, CAST(c.create_ts AS DATE) as create_ts, count(1) as rc
FROM [edw_integration].[claim_clue_property_feed] AS c
WHERE claimReportingStatus = 'A'
GROUP BY c.claimNumber, c.claimReportingStatus, CAST(c.create_ts AS DATE)
HAVING COUNT(1) > 1
ORDER BY 3 DESC
;

SELECT * FROM [edw_integration].[claim_clue_property_feed] WHERE ClaimNumber = 'C24HOA00100';-- Different values in mortgageName, mortgageLoanNumber
SELECT * FROM [edw_integration].[claim_clue_property_feed] WHERE ClaimNumber = 'C23HOA00941';-- Identical rows


SELECT * FROM [edw_temp].[claim_clue_property_feed_temp0];
SELECT * FROM [edw_temp].[claim_clue_property_feed_temp2]; --where claimNumber='C23HOA00966';
SELECT * FROM [edw_temp].[claim_clue_property_feed_temp1]; --where claimNumber='C23HOA00966';
-- ********** Duplicates by claimReportingStatus A ************


SELECT 
    mortgagee_nm, loan_no, *
FROM edw_core.tmortgagee 
WHERE 1=1
AND mortgagee_type = 'First' 
AND mortgagee_no = '1'
AND policy_no = 'HO100012583-02' --in ('HO100208366-03','HO100104384-02')
ORDER BY policy_no
;


select policy_no, count(1) from edw_core.tcollection_location group by policy_no having count(1) > 1
;

SELECT 
    m.policy_no,
    count(1)
    -- m.mortgagee_nm,
    -- m.loan_no,
    --      LEFT(m.mortgagee_nm, 30) AS [mortgageName],
    --         LEFT(m.loan_no, 15)  AS [mortgageLoanNumber]
FROM edw_core.tmortgagee as m
LEFT join edw_core.tpolicy_history as ph
-- on m.policy_history_sk = ph.policy_history_sk AND ph.latest_transaction_in = 'Y'
on m.policy_no = ph.policy_no AND ph.latest_transaction_in = 'Y'
WHERE m.mortgagee_type = 'First' 
AND m.mortgagee_no = '1'
-- AND ph.policy_history_sk is null
-- AND m.policy_no in ('HO100208366-03','HO100104384-02','HO100012583-02')
group by m.policy_no 
having count(1) > 1
;

select 
    m.policy_no,
    m.mortgagee_nm,
    m.loan_no,m.policy_history_sk,ph.policy_history_sk
FROM edw_core.tmortgagee as m
LEFT JOIN edw_core.tpolicy_history as ph
ON m.policy_no = ph.policy_no    AND ph.latest_transaction_in = 'Y'
WHERE m.mortgagee_type = 'First'
AND m.mortgagee_no = '1'
and ph.policy_history_sk is null
;

select * FROM edw_core.tmortgagee where policy_no = 'HO100013340-02';
select * FROM edw_core.tpolicy_history where policy_no = 'HO100013340-02';

select * FROM edw_core.tmortgagee where policy_history_sk = 129670;
select * FROM edw_core.tpolicy_history where policy_history_sk = 129670;


select * FROM edw_core.tmortgagee where policy_no = 'HO100013575-03';
select * FROM edw_core.tpolicy_history where policy_no = 'HO100013575-03';

SELECT policy_no, mortgagee_nm, loan_no, 
ROW_NUMBER() OVER(PARTITION BY policy_no ORDER BY mortgage_sk DESC) as rn,
*
-- select policy_no, COUNT(1)
FROM edw_core.tmortgagee 
WHERE mortgagee_type = 'First'
AND mortgagee_no = '1'
AND policy_no = 'HO100032451-04'--'HO100013575-03'
-- GROUP BY policy_no HAVING COUNT(1) > 1
;

WITH
mortagee AS (
    SELECT 
        m.policy_no,
        m.mortgagee_nm,
        m.loan_no,
        ROW_NUMBER() OVER(PARTITION BY m.policy_no, m.effective_dt ORDER BY transaction_seq_no DESC) as rn
    FROM edw_core.tmortgagee as m
    WHERE m.mortgagee_type = 'First' 
    AND m.mortgagee_no = '1'
)
select policy_no, count(1) from mortagee where rn = 1 group by policy_no having count(1) > 1 --check duplicates
-- SELECT * FROM edw_core.tmortgagee m LEFT JOIN mortagee as mm on m.policy_no = mm.policy_no AND mm.rn = 1 WHERE m.mortgagee_type = 'First' AND m.mortgagee_no = '1' AND mm.policy_no is null --check
;


SELECT policy_no, mortgagee_nm, loan_no, 
ROW_NUMBER() OVER(PARTITION BY policy_no ORDER BY mortgage_sk DESC) as rn,
*
-- select policy_no, COUNT(1)
FROM edw_core.tmortgagee 
WHERE mortgagee_type = 'First'
AND mortgagee_no = '1'
AND policy_no = 'HO100032451-04'--'HO100013575-03'


-- ********** Duplicates by claimNumber, create_ts, claimReportingStatus ************
SELECT claimNumber, create_ts, claimReportingStatus, count(1) FROM [edw_integration].[claim_clue_property_feed] group by claimNumber, create_ts, claimReportingStatus having count(1) > 1;

-- ********** Duplicates by claimNumber, create_ts, claimReportingStatus ************


-- ********** Two Files sent with 2024100920241009 ************

SELECT create_ts, report_start_date, report_end_date, COUNT(1) as rc
FROM [edw_integration].[claim_clue_property_feed]
GROUP BY create_ts, report_start_date, report_end_date
ORDER BY create_ts DESC
;


SELECT TOP 1  
    CONVERT(VARCHAR(8), report_start_date, 112) + CONVERT(VARCHAR(8), report_end_date, 112) AS start_end_date
FROM [edw_integration].[claim_clue_property_feed]
WHERE 
    -- CAST(create_ts AS DATE) = (SELECT MAX(CAST(create_ts AS DATE)) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
    CAST(create_ts AS DATE) = '2024-10-11 00:00:00'
ORDER BY start_end_date desc
;
-- ********** Two Files sent with 2024100920241009 ************