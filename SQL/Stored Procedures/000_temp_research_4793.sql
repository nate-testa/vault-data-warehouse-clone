-- VI-28558 AU100076620-03: OTC prem does not match between DW 2.0 policyImageId 1771578 & EDW 3.0 policy_history_sk = 178409

SELECT * FROM edw_core.tpolicy WHERE policy_no LIKE 'AU100076620%';

--query proposed


-- LOOKUP ISS Auto Call Year 2023
-- Casandra Lane, 2024-01-05
-- starting from scratch.  Hooray.
WITH
Tmp_Variables as (
    SELECT '2022-01-01' as YearStart
          ,'2023-01-01' as YearEnd
--          ,'AZ' as ISS_State
)
--, TESTING AS (
   SELECT 
       p.policy_no
     , p.risk_state_cd
     , p.effective_dt
     , p.policy_sk
     , ph.policy_history_sk
     , ph.transaction_effective_dt
     , ph.transaction_ts
     , ph.transaction_type
     , ph.transaction_seq_no
     , pt.premium_amt
     , pt.vehicle_coverage_sk
     , ic.internal_coverage_desc
     , av.vehicle_model_year
     , av.vehicle_make
     , av.vehicle_model
     , av.vehicle_vin 
     , avc.auto_vehicle_coverage_sk
     , avc.auto_vehicle_sk
     , ic.aslob_cd
     , ic.internal_coverage_category_nm
FROM edw_core.tpolicy p 
JOIN edw_core.tpolicy_history ph ON ph.policy_sk = p.policy_sk
JOIN edw_core.tpolicy_transaction pt ON pt.policy_sk = p.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no
JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
LEFT JOIN edw_core.tauto_vehicle av ON av.auto_vehicle_sk = pt.item_sk
LEFT JOIN edw_core.tauto_vehicle_coverage avc ON avc.auto_vehicle_sk = av.auto_vehicle_sk
                                                and avc.policy_history_sk = ph.policy_history_sk
WHERE  1=1
--   and p.risk_state_cd = (SELECT ISS_State from Tmp_Variables)  -- file is too big to run for more than one state at a time
   and p.policy_no = 'AU100076620-03'  -- testing only
   and av.vehicle_vin = 'U15G1R42559'  -- testing only
   and ic.internal_coverage_desc = 'Other Than Collision'  -- testing only
 --  and ph.policy_history_sk = 178409 -- testing only
   and ph.premium_amt <> 0
   and p.product_cd = 'AU'  -- excludes coverages that apply to other products, which might be included in the join
   and ic.internal_coverage_category_nm = 'Premium'  -- we only report on premium amounts
   and ph.transaction_seq_no = 1
   -- and av.vehicle_vin = 'U15G1R42559'
   -- and ic.internal_coverage_desc = 'Property Protection Insurance'
--   and greatest(ph.transaction_effective_dt, transaction_ts) between (SELECT YearStart from Tmp_Variables) and (SELECT YearEnd from Tmp_Variables)
-- ORDER BY p.effective_dt, ph.transaction_seq_no, av.vehicle_vin, vehicle_coverage_sk, internal_coverage_cd

;

-- 'AU100028533-01'  
WITH tbl AS (
    SELECT 
        p.policy_no
        ,p.risk_state_cd
        -- ,p.effective_dt
        ,p.policy_sk
        -- ,ph.policy_history_sk
        ,ph.transaction_effective_dt
        -- ,ph.transaction_ts
        -- ,ph.transaction_type
        ,ph.transaction_seq_no
        ,pt.premium_amt
        ,pt.vehicle_coverage_sk
        ,ic.internal_coverage_desc
        ,ic.internal_coverage_sk
        ,av.vehicle_model_year
        ,av.vehicle_make
        ,av.vehicle_model
        ,av.vehicle_vin 
        ,avc.auto_vehicle_coverage_sk
        ,avc.auto_vehicle_sk
        ,ic.aslob_cd
        ,ic.internal_coverage_category_nm
        ,pt.source_system_sk
    FROM edw_core.tpolicy p 
    JOIN edw_core.tpolicy_history ph ON ph.policy_sk = p.policy_sk
    JOIN edw_core.tpolicy_transaction pt ON pt.policy_sk = p.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no
    JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
    LEFT JOIN edw_core.tauto_vehicle av ON av.auto_vehicle_sk = pt.item_sk
    LEFT JOIN edw_core.tauto_vehicle_coverage avc ON avc.auto_vehicle_sk = av.auto_vehicle_sk AND avc.policy_history_sk = ph.policy_history_sk
    WHERE  1=1
        AND p.policy_no LIKE 'AU100076620-03'
        AND p.product_cd = 'AU'
        -- AND ph.premium_amt <> 0
     --    AND ic.internal_coverage_desc LIKE '%Other%'
)

select 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   auto_vehicle_sk,
   internal_coverage_sk,
   internal_coverage_desc, 
   sum(premium_amt) 
from tbl
where vehicle_vin = 'U15G1R42559'
group by 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   auto_vehicle_sk,
   internal_coverage_sk,
   internal_coverage_desc
;

select * from edw_core.tpolicy where policy_no = 'AU100076620-03';
select * from edw_stage.AccountTransaction where PolicyNumber = 'AU100076620-03';
SELECT distinct item_sk FROM edw_core.tpolicy_transaction WHERE policy_sk = 106890;
SELECT * FROM edw_core.tauto_vehicle where auto_vehicle_sk in (20673,31559,33252,39256,39580,40594);
select * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = '662c134a-94e4-49b3-9ffc-d22c7dbd10d5';

--**UPDATES**
--otcPrem - Other Than Collision update premium_amt(PremiumDeltaProRated) from 90 to 84
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 106890 and item_sk = 31559 and internal_coverage_sk = 100 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage, * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = '662c134a-94e4-49b3-9ffc-d22c7dbd10d5' and PremiumDeltaProRated = '90' and id = 675868;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '84', CommissionDeltaProRated = 84*0.15 where AccountTransactionId = '662c134a-94e4-49b3-9ffc-d22c7dbd10d5' and PremiumDeltaProRated = '90' and id = 675868;
