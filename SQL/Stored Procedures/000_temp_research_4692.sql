--on vault

-- LOOKUP ISS Auto Call Year 2023
-- Casandra Lane, 2024-01-05
-- starting from scratch.  Hooray.
WITH
Tmp_Variables as (
    SELECT '2022-01-01' as YearStart
          ,'2023-01-01' as YearEnd
--          ,'AZ' as ISS_State
)
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
   and p.policy_no = 'AU100028533-01'  -- testing only
--   and av.vehicle_vin = '1GNSCHKC6LR175706'  -- testing only
--   and ic.internal_coverage_desc = 'Bodily Injury'  -- testing only
   and ph.policy_history_sk = 154493 -- testing only
   and ph.premium_amt <> 0
   and p.product_cd = 'AU'  -- excludes coverages that apply to other products, which might be included in the join
   and ic.internal_coverage_category_nm = 'Premium'  -- we only report on premium amounts
--   and greatest(ph.transaction_effective_dt, transaction_ts) between (SELECT YearStart from Tmp_Variables) and (SELECT YearEnd from Tmp_Variables)
-- ORDER BY p.effective_dt, ph.transaction_seq_no, av.vehicle_vin, vehicle_coverage_sk, internal_coverage_cd
;

SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100028533-01';

SELECT * FROM edw_core.tpolicy_transaction pt 
JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
WHERE pt.policy_sk = 26686
;


SELECT COUNT(1) FROM edw_core.tauto_vehicle_coverage WHERE auto_garage_location_sk IS NULL;--0