select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_auto_feed');
update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed');
-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed];
SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed];
-- EXEC [edw_core].[sp_claim_clue_auto_feed];
EXEC sp_help '[edw_integration].[claim_clue_auto_feed]';
----------------------------------------------------------------------------

 SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed]
    WHERE 
        PolicyNumber NOT IN ('AU100108958-03','AU100089866-01');

-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:303 Error Message:String or binary data would be truncated in table 'vault_edw.edw_integration.claim_clue_auto_feed', column 'ClaimNumber'. Truncated value: '25ATBRITISH COLUMBIA'.
-- CASE OF CLAIM NUMBER
SELECT TOP 10 * FROM edw_core.tclaim WHERE claim_no like '%COLUMBIA%';


select TOP 10 transaction_ts, * from edw_core.tclaim_transaction where policy_sk in (select policy_sk from edw_core.tpolicy where policy_no = 'AU100027502-04');
-- update edw_core.tclaim_transaction set transaction_ts = '1900-01-01' where claim_transaction_sk = 113145;

-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:303 Error Message:Violation of UNIQUE KEY constraint 'uidx_claim_clue_auto_feed'. Cannot insert duplicate key in object 'edw_integration.claim_clue_auto_feed'. The duplicate key value is (C20AUA00027         , PD, Jun 29 2020 12:00AM).
-- Unique Key: ClaimNumber, ClaimType, report_start_date
SELECT * FROM [edw_temp].[claim_clue_auto_feed_temp1] WHERE ClaimNumber = 'C20AUA00027';


----------------------------------------------------------------------------


SELECT 
    PolicyHolderMailAddressStreetName, PolicyHolderMailAddressCity, PolicyHolderMailAddressState, PolicyHolderMailAddressZip, policyHolderNameFirst, 
    policyHolderNameLast, claimReportingStatus, claimAmount, claimtype, policyNumber, policyType, contribCompany, claimNumber, claimAmount
FROM edw_integration.claim_clue_auto_feed 
-- WHERE LTRIM(RTRIM(policyType)) = '';
WHERE 
    LTRIM(RTRIM(PolicyHolderMailAddressStreetName)) = '' OR 
    LTRIM(RTRIM(PolicyHolderMailAddressCity)) = '' OR 
    LTRIM(RTRIM(PolicyHolderMailAddressState)) = '' OR 
    LTRIM(RTRIM(PolicyHolderMailAddressZip)) = '' OR 
    LTRIM(RTRIM(policyHolderNameFirst)) = '' OR 
    LTRIM(RTRIM(policyHolderNameLast)) = '' OR 
    LTRIM(RTRIM(claimReportingStatus)) = '' OR 
    LTRIM(RTRIM(claimAmount)) = '' OR 
    LTRIM(RTRIM(claimtype)) = '' OR 
    LTRIM(RTRIM(policyNumber)) = '' OR 
    LTRIM(RTRIM(policyType)) = '' OR 
    LTRIM(RTRIM(contribCompany)) = '' OR --NOT NULL
    LTRIM(RTRIM(claimNumber)) = '' OR --NOT NULL
    claimAmount LIKE '%-%'
;

---------------------------------------------------------------
SELECT * FROM edw_integration.claim_clue_auto_feed WHERE PolicyType IS NULL OR PolicyType = '';

with 
final_c as (
	SELECT * 
	FROM edw_integration.claim_clue_auto_feed WHERE        
	LTRIM(RTRIM(PolicyHolderMailAddressStreetName)) = '' OR         
	LTRIM(RTRIM(PolicyHolderMailAddressCity)) = '' OR         
	LTRIM(RTRIM(PolicyHolderMailAddressState)) = '' OR      
	LTRIM(RTRIM(PolicyHolderMailAddressZip)) = '' OR        
	LTRIM(RTRIM(policyHolderNameFirst)) = '' OR         
	LTRIM(RTRIM(policyHolderNameLast)) = '' OR    
	LTRIM(RTRIM(claimReportingStatus)) = '' OR       
	LTRIM(RTRIM(claimAmount)) = '' OR        
	LTRIM(RTRIM(claimtype)) = '' OR      
	LTRIM(RTRIM(policyNumber)) = '' OR        
	LTRIM(RTRIM(policyType)) = '' OR        
	LTRIM(RTRIM(contribCompany)) = '' OR    
	LTRIM(RTRIM(claimNumber)) = '' OR        
	claimAmount LIKE '%-%'
)
,tt as (
	select * from final_c
	where PolicyType = ''
    OR PolicyType IS NULL
	--and ClaimReportingStatus = 'A'
)            
-- select * from tt;
select 
	v.policy_no, v.vehicle_type, v.source_system_sk, tt.PolicyNumber, tt.PolicyType,
    CASE 
        WHEN v.vehicle_type = 'Collector Car' THEN 'PA'
        WHEN v.vehicle_type = 'Dune Buggy' THEN 'CY'
        WHEN v.vehicle_type = 'Motor Home' THEN 'MH'
        WHEN v.vehicle_type = 'Motorcycles / Mopeds / Scooter / Go Karts' THEN 'CY'
        WHEN v.vehicle_type = 'Private Passenger Auto' THEN 'PA'
        WHEN v.vehicle_type = 'Recreational Trailer' THEN 'PA'
        WHEN v.vehicle_type = 'Snowmobile / ATV' THEN 'CY'
        WHEN v.vehicle_type = 'Golf Cart' THEN 'PA'
    END AS [PolicyType_2]
from edw_core.tauto_vehicle v 
inner join tt 
on v.policy_no = tt.PolicyNumber
;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Check why the column PolicyType is empty or null for some policies
------------------------------------------------------------------------------
WITH 
claims AS (
    SELECT 
        c.claim_sk
        ,c.claim_no
        ,c.policy_sk
        ,c.policy_no
        ,c.cause_of_loss_sk
        ,c.catastrophe_sk
        ,c.loss_dt
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
            WHEN claim_coverage_desc = 'PIP' THEN 'OT'
            WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
            WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
            WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UN'
            ELSE 'OT'
        END AS [ClaimType],
        SUM(
            COALESCE(
                    (
                        a.loss_paid_amt                     +
                        a.expense_paid_amt                  +
                        a.defense_paid_amt                  +
                        a.overpayment_recovery_amt          +
                        a.overpayment_expense_recovery_amt  +
                        a.overpayment_defense_recovery_amt
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
    -- AND cast(b.transaction_ts as datetime2(7)) > @last_source_extract_ts
    GROUP BY
        a.claim_sk,
        b.transaction_ts,
        CASE
            WHEN claim_coverage_desc = 'Combined Single Limits' THEN 'BI'
            WHEN claim_coverage_desc = 'Collision' THEN 'CO'
            WHEN claim_coverage_desc = 'Comprehensive' THEN 'CP'
            WHEN claim_coverage_desc = 'Full Glass' THEN 'GL'
            WHEN claim_coverage_desc = 'Medical Payments' THEN 'MP'
            WHEN claim_coverage_desc = 'PIP' THEN 'OT'
            WHEN claim_coverage_desc = 'PD Liability Limit' THEN 'PD'
            WHEN claim_coverage_desc = 'Roadside Assistance' THEN 'TL'
            WHEN claim_coverage_desc = 'Uninsured Motorist Liablity' THEN 'UN'
            ELSE 'OT'
        END
)
,claim_feature_item AS (
    SELECT 
        claim_sk, item_sk, rc
    FROM (
        SELECT 
            claim_sk,
            item_sk,
            rc,
            ROW_NUMBER() OVER (PARTITION BY claim_sk ORDER BY rc DESC, item_sk DESC) AS rn
        FROM (
            SELECT a.claim_sk, a.item_sk, COUNT(*) AS rc
            FROM edw_core.tclaim_feature a
            INNER JOIN claim_feature b ON a.claim_sk = b.claim_sk
            GROUP BY a.claim_sk, a.item_sk
        ) AS counts
    ) AS ranked
    WHERE rn = 1
)

SELECT item_sk, * FROM edw_core.tclaim_feature where claim_sk IN (1017,9505);
-- SELECT * FROM claim_feature where claim_sk IN (1017,9505);
-- SELECT * FROM claims where claim_sk IN (1017,9505);
-- SELECT * FROM edw_core.tpolicy where policy_sk IN (136625,24888);
-- SELECT * FROM claim_feature_item where claim_sk IN (1017,9505);

-- SELECT a.claim_sk, a.item_sk, COUNT(*) AS rc
-- FROM edw_core.tclaim_feature a
-- INNER JOIN claim_feature b ON a.claim_sk = b.claim_sk
-- WHERE a.claim_sk IN (1017,9505)
-- GROUP BY a.claim_sk, a.item_sk
-- ;

-- SELECT
--     cf.claim_sk,
--     c.policy_no,
--     cfi.item_sk,
--     av.auto_vehicle_sk,
--     av.vehicle_type,
--     CASE 
--         WHEN av.vehicle_type = 'Collector Car' THEN 'PA'
--         WHEN av.vehicle_type = 'Dune Buggy' THEN 'CY'
--         WHEN av.vehicle_type = 'Motor Home' THEN 'MH'
--         WHEN av.vehicle_type = 'Motorcycles / Mopeds / Scooter / Go Karts' THEN 'CY'
--         WHEN av.vehicle_type = 'Private Passenger Auto' THEN 'PA'
--         WHEN av.vehicle_type = 'Recreational Trailer' THEN 'PA'
--         WHEN av.vehicle_type = 'Snowmobile / ATV' THEN 'CY'
--         WHEN av.vehicle_type = 'Golf Cart' THEN 'PA'
--     END AS [PolicyType]
-- FROM claim_feature AS cf
-- INNER JOIN claims AS c ON cf.claim_sk = c.claim_sk
-- INNER JOIN edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
-- LEFT JOIN claim_feature_item AS cfi ON cf.claim_sk = cfi.claim_sk
LEFT JOIN edw_core.tauto_vehicle AS av ON cfi.item_sk = av.auto_vehicle_sk
-- WHERE 1=1
-- AND p.product_cd IN ('AU')
-- AND cf.claim_sk in (1017,9505)
-- AND av.auto_vehicle_sk IS NULL
;

SELECT item_sk, * FROM edw_core.tclaim_feature 
WHERE claim_sk in (1017,9505)
;

-- SELECT COUNT(1) FROM edw_core.tclaim_feature WHERE item_sk IS NULL;


-----------------------------------------------------------------------------------

