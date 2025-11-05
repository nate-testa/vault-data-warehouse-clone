select TOP 100 * from edw_core.tetl_audit where process_nm like '%sp_claim_clue_property_feed%' order by etl_audit_sk desc GO
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_property_feed') GO
-- update edw_core.tetl_control set last_source_extract_ts = '2025-09-05 19:33:11.0333333' where process_nm in ('sp_claim_clue_property_feed') GO
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed') GO
-- EXEC sp_help '[edw_integration].[claim_clue_auto_feed]' GO
-- EXEC sp_help '[edw_integration].[claim_clue_property_feed]' GO
-- last_source_extract_ts >2025-09-05 19:33:11.0333333 AND last_source_extract_ts <=2025-08-18 22:14:46.9933333

SELECT COUNT(1) FROM [edw_temp].[claim_clue_auto_feed_bk_20250812] where claimReportingStatus = 'A' GO--7380
SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed] GO --where claimReportingStatus = 'A' GO--7427

-- SELECT * INTO [edw_temp].[claim_clue_auto_feed_bk_20250812] FROM [edw_integration].[claim_clue_auto_feed] GO
-- SELECT * INTO [edw_temp].[claim_clue_property_feed_bk_20250827] FROM [edw_integration].[claim_clue_property_feed] GO

-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed] GO
-- TRUNCATE TABLE [edw_integration].[claim_clue_property_feed] GO

-- EXEC [edw_core].[sp_claim_clue_auto_feed] GO
-- EXEC [edw_core].[sp_claim_clue_property_feed] GO

-- edw_core.tclaim_transaction GO

SELECT ROW_NUMBER() OVER (PARTITION BY claimNumber ORDER BY etl_audit_sk DESC, claimReportingStatus ASC) RN  , * FROM [edw_temp].[claim_clue_property_feed_bk_20250812] where policyNumber = '9100146 173501A' and claimNumber = 'C20HOA00058' order by report_start_date desc GO--ClaimReportingStatus = 'A' --14019

WITH tbl AS (
SELECT ROW_NUMBER() OVER (PARTITION BY claimNumber ORDER BY etl_audit_sk DESC, claimReportingStatus ASC) RN  , * FROM [edw_temp].[claim_clue_property_feed_bk_20250812]
)
SELECT COUNT(1) FROM tbl where RN = 1
 GO

select * from edw_integration.claim_clue_property_feed where policyNumber = '9100146 173501A' and claimNumber = 'C20HOA00058' GO--ClaimReportingStatus = 'A'--4085




----------------------------------------------------------------------------
-- *** CLUE Property
----------------------------------------------------------------------------
-- Case 1 -- C23HOA00256
-- select * into [edw_temp].[claim_clue_property_feed_bk_20250915] from [edw_integration].[claim_clue_property_feed] GO
SELECT report_end_date ,report_start_date ,create_ts ,* FROM [edw_integration].[claim_clue_property_feed] where claimNumber = 'C23HOA00256' order by 3 desc GO
SELECT TOP 10 * FROM [edw_temp].[claim_clue_property_feed_bk_20250915] where claimNumber = 'C23HOA00256' GO
select * from edw_core.tclaim_transaction where claim_sk in (select claim_sk from edw_core.tclaim where claim_no = 'C23HOA00256') order by claim_transaction_sk desc GO
select * from edw_core.tclaim where claim_no = 'C23HOA00256' GO
select * from [edw_integration].[claim_clue_property_feed] where etl_audit_sk > 248036 GO
SELECT etl_audit_sk, count(1) rc FROM [edw_integration].[claim_clue_property_feed] GROUP BY etl_audit_sk ORDER BY 1 DESC GO


SELECT COUNT(1) FROM [edw_temp].[claim_clue_property_feed_bk_20250915] GO--21755
SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed] GO--21755

-- truncate table [edw_integration].[claim_clue_property_feed] GO

-- insert into [edw_integration].[claim_clue_property_feed]
-- select * from [edw_temp].[claim_clue_property_feed_bk_20250915] GO

-- EXEC [edw_core].[sp_claim_clue_property_feed] GO


-- Case 2 -- C24HOA00054
SELECT report_end_date ,report_start_date ,create_ts ,* FROM [edw_temp].[claim_clue_property_feed_bk_20250812] where claimNumber = 'C24HOA00054' order by 3 desc GO
select * from edw_core.tclaim_transaction where claim_sk in (select claim_sk from edw_core.tclaim where claim_no = 'C24HOA00054') order by claim_transaction_sk desc GO
select * from edw_core.tclaim where claim_no = 'C24HOA00054' GO




-------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------
-- *** CLUE AUTO
------------------------------------------------------------------------------------------------------------------------------
select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp_claim_clue_auto_feed%' order by etl_audit_sk desc GO
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_auto_feed') GO
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01' where process_nm in ('sp_claim_clue_auto_feed') GO
-- EXEC sp_help '[edw_integration].[claim_clue_auto_feed]' GO

-- select * into edw_temp.claim_clue_auto_feed_bk_20251022 from edw_integration.claim_clue_auto_feed GO
-- select count(1) from edw_temp.claim_clue_auto_feed_bk_20251022 GO



select count(1) from edw_integration.claim_clue_auto_feed GO
-- truncate table edw_integration.claim_clue_auto_feed GO
-- EXEC [edw_core].[sp_claim_clue_auto_feed] GO


SELECT etl_audit_sk, count(1) rc FROM [edw_integration].[claim_clue_auto_feed] GROUP BY etl_audit_sk ORDER BY 1 DESC GO
select * from edw_integration.claim_clue_auto_feed where etl_audit_sk > 250659 GO
select * from edw_integration.claim_clue_auto_feed where claimNumber = 'C20AUA00002' order by create_ts desc GO


SELECT * FROM edw_integration.claim_clue_auto_feed
WHERE PolicyNumber IN ('9102706 323401A',     
'9102706 323401A'     
) GO

SELECT *
FROM edw_integration.claim_clue_auto_feed WHERE             
LTRIM(RTRIM(policyHolderNameFirst)) = '' OR   --184      
LTRIM(RTRIM(policyHolderNameLast)) = '' 
 GO


-- select * into edw_temp.claim_clue_auto_feed_bk20250916 from edw_integration.claim_clue_auto_feed GO

select 'bk' as tbl, * from edw_temp.claim_clue_auto_feed_bk20250916 where claimNumber in ('25ATUN357320239') union all
select 'tbl' as tbl, * from edw_integration.claim_clue_auto_feed where claimNumber in ('25ATUN357320239')  GO
select * from edw_core.tclaim_transaction where claim_sk in (select claim_sk from edw_core.tclaim where claim_no in ('25ATUN357320239'))  GO
select * from edw_core.tclaim_feature WHERE claim_no = '25ATUN357320239' GO
select * from edw_core.tclaim where claim_no = 'C20AUA00002' GO


select top 10 * from edw_integration.claim_clue_auto_feed GO
select top 10 * from edw_core.tclaim_feature GO

exec sp_help 'edw_core.tclaim_feature' GO


with claim_feature AS (
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
LEFT JOIN claim_feature_item AS cfi ON cf.claim_sk = cfi.claim_sk
LEFT JOIN edw_core.tauto_vehicle AS av ON cfi.item_sk = av.auto_vehicle_sk
LEFT JOIN customer AS cu ON p.customer_id = cu.customer_id
 GO