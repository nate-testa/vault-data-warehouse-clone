--see Auto policies by coverage

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
        AND p.policy_no LIKE 'AU100028533-01'
        AND p.product_cd = 'AU'
        -- AND ph.premium_amt <> 0
        -- AND ic.internal_coverage_desc LIKE 'Auto%Death%'
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
-- where vehicle_vin = '1GYS4GKL2NR156499'
group by 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   auto_vehicle_sk,
   internal_coverage_sk,
   internal_coverage_desc
;

--**UPDATES**
--otcPrem - Other Than Collision update premium_amt(PremiumDeltaProRated) from 90 to 84
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 87210 and item_sk = 36404 and internal_coverage_sk = 104 order by transaction_seq_no;
select * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = '662c134a-94e4-49b3-9ffc-d22c7dbd10d5' and PremiumDeltaProRated = '90' and id = 675868;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '84' where AccountTransactionId = '662c134a-94e4-49b3-9ffc-d22c7dbd10d5' and PremiumDeltaProRated = '90' and id = 675868;
