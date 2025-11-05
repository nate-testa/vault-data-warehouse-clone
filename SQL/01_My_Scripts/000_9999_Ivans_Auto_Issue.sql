select top 100 * from edw_core.tetl_audit where process_nm like '%policy_ivans_auto_feed%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '2025-01-01 00:00:00' where process_nm = 'sp_policy_ivans_auto_feed';
-- truncate table [edw_integration].[policy_ivans_auto_feed];
-- EXEC [edw_core].[sp_policy_ivans_auto_feed];
select count(1) from [edw_integration].[policy_ivans_auto_feed];
-- select top 100 * from [edw_integration].[policy_ivans_auto_feed];
;

select au_coverages, * from edw_integration.policy_ivans_auto_feed where PolicyNumber_031 = 'AU100171150-03';
select * from edw_core.tpolicy where policy_no = 'AU100171150-03';
select top 10 * from edw_core.tpolicy_transaction where policy_sk = 163687;

--Table 1
SELECT 
pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk,
MAX(ph.transaction_ts) as transaction_ts, 
SUM(pt.premium_amt) as premium_amt,
CASE WHEN pt.policy_transaction_type_sk = 5
    THEN
        (SELECT SUM(subpt.premium_amt)
            FROM edw_core.tpolicy_transaction subpt
            WHERE subpt.policy_sk = pt.policy_sk
            AND subpt.transaction_seq_no <= pt.transaction_seq_no)
    ELSE
        (SELECT SUM(subpt.annual_premium_amt)
            FROM edw_core.tpolicy_transaction subpt
            WHERE subpt.policy_sk = pt.policy_sk
            AND subpt.transaction_seq_no <= pt.transaction_seq_no)
END AS annual_premium_amt
-- INTO [edw_temp].[policy_ivans_auto_feed_temp2]
FROM edw_core.tpolicy_transaction as pt
INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
INNER JOIN edw_core.policy_ivans_auto_feed as ph 
ON pt.policy_sk = ph.policy_sk
AND pt.transaction_seq_no = ph.transaction_seq_no
WHERE 1=1
AND pr.product_cd = 'AU'
-- AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
AND pt.policy_sk = 163687
GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk
;

-- Table 2
SELECT
    ic.internal_coverage_cd , apc.limit_type, apc.medical_payment_limit_amt, apc.combined_single_limit_amt,
    CASE 
        WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Underinsured Motorist'    THEN 'umCSLPrem'
        WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Uninsured Motorist'    THEN 'umCSLPrem'
        ELSE ic.internal_coverage_cd
    END AS coverageCd,
    CASE 
        WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Underinsured Motorist'    THEN 'umCSLPrem'
        WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Uninsured Motorist'    THEN 'umCSLPrem'
        ELSE ic.internal_coverage_desc
    END AS coverageDesc,
    CASE
        WHEN apc.limit_type = 'Combined' then apc.combined_single_limit_amt
        WHEN ic.internal_coverage_cd = 'Added First Party' then apc.added_first_party_limit_amt
        WHEN ic.internal_coverage_cd = 'Bodily Injury' then apc.bodily_injury_limit_amt
        WHEN ic.internal_coverage_cd = 'Basic First Party' then apc.combination_fpb_limit_amt
        WHEN ic.internal_coverage_cd = 'Auto Death Disability' then apc.accidental_death_benefit_limit_amt
        WHEN ic.internal_coverage_cd = 'Medical Payments' then apc.medical_payment_limit_amt
        WHEN ic.internal_coverage_cd = 'Personal Injury Protection' then apc.pip_limit_amt
        WHEN ic.internal_coverage_cd = 'Property Damage' then apc.property_damage_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Split' then apc.underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Combined' then apc.combined_um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Combined' then apc.combined_um_pd_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Split' then apc.uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Split' then apc.um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Split' then apc.um_pd_policy_limit_amt
        ELSE '' 
    END 	AS limits_Current,
    CASE 
        WHEN ic.internal_coverage_cd = 'Added First Party' then apc.added_first_party_limit_amt
        WHEN ic.internal_coverage_cd = 'Bodily Injury' then apc.bodily_injury_limit_amt
        WHEN ic.internal_coverage_cd = 'Basic First Party' then apc.combination_fpb_limit_amt
        WHEN ic.internal_coverage_cd = 'Auto Death Disability' then apc.accidental_death_benefit_limit_amt
        WHEN ic.internal_coverage_cd = 'Medical Payments' then apc.medical_payment_limit_amt
        WHEN ic.internal_coverage_cd = 'Personal Injury Protection' then apc.pip_limit_amt
        WHEN ic.internal_coverage_cd = 'Property Damage' then apc.property_damage_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Split' then apc.underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Combined' then apc.combined_um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Combined' then apc.combined_um_pd_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Split' then apc.uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Split' then apc.um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Split' then apc.um_pd_policy_limit_amt 
        WHEN apc.limit_type = 'Combined' then apc.combined_single_limit_amt
        ELSE '' 
    END 	AS limits_New,
    CASE
        WHEN ic.internal_coverage_cd = 'Medical Payments' then apc.medical_payment_limit_amt
        WHEN ic.internal_coverage_cd = 'Personal Injury Protection' then apc.pip_limit_amt
        WHEN apc.limit_type = 'Combined' then apc.combined_single_limit_amt
        WHEN ic.internal_coverage_cd = 'Added First Party' then apc.added_first_party_limit_amt
        WHEN ic.internal_coverage_cd = 'Bodily Injury' then apc.bodily_injury_limit_amt
        WHEN ic.internal_coverage_cd = 'Basic First Party' then apc.combination_fpb_limit_amt
        WHEN ic.internal_coverage_cd = 'Auto Death Disability' then apc.accidental_death_benefit_limit_amt
        WHEN ic.internal_coverage_cd = 'Property Damage' then apc.property_damage_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Split' then apc.underinsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Combined' then apc.combined_um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Combined' then apc.combined_um_pd_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Split' then apc.uninsured_motorist_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Split' then apc.um_bi_policy_limit_amt
        WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Split' then apc.um_pd_policy_limit_amt 
        ELSE '' 
    END 	AS limits_other,
    pt.annual_premium_amt AS currentTermAmt,
    pt.premium_amt AS netChangeAmt
FROM 
    (
        SELECT 
            pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk,
            (
                SELECT SUM(subpt.annual_premium_amt)
                FROM edw_core.tpolicy_transaction subpt 
                WHERE subpt.policy_sk = pt.policy_sk
                AND subpt.effective_dt_sk = pt.effective_dt_sk
                AND subpt.internal_coverage_sk = pt.internal_coverage_sk
                AND subpt.transaction_seq_no <= pt.transaction_seq_no
            ) as annual_premium_amt,
            SUM(pt.premium_amt) AS premium_amt 
        FROM edw_core.tpolicy_transaction as pt
        INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
        INNER JOIN edw_core.tpolicy_history as ph 
        ON pt.policy_sk = ph.policy_sk
        AND pt.transaction_seq_no = ph.transaction_seq_no
        WHERE 1=1
            AND pr.product_cd = 'AU'
        -- AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
        AND pt.policy_sk = 163687
        GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk
    ) as pt 
    INNER JOIN edw_core.tauto_policy_coverage as apc ON pt.coverage_sk = apc.auto_policy_coverage_sk
    INNER JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
;

select count(1) from edw_core.polic;