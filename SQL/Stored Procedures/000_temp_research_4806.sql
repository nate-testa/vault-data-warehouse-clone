SELECT * FROM edw_core.tsource_system;
SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100220887';

SELECT 
    ph.policy_no, ph.transaction_seq_no, ss.source_system_nm
FROM edw_core.tpolicy_history AS ph
INNER JOIN edw_core.tsource_system AS ss ON ph.source_system_sk = ss.source_system_sk
WHERE policy_no IN ('AU100220887','AU100220887-01','AU100226371-01','AU100226458-01','AU100227231','AU100227231-01','AU100227700')
GROUP BY 
    ph.policy_no, ph.transaction_seq_no, ss.source_system_nm
ORDER BY policy_no, transaction_seq_no
;

--  MI PPI EDW 3.0, to compare to DW 2.0
-- Casandra Lane, 2024-01-05
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
     , ic.internal_coverage_desc
     , av.vehicle_model_year
     , av.vehicle_make
     , av.vehicle_model
     , av.vehicle_vin 
     , avc.auto_vehicle_coverage_sk
     , avc.auto_vehicle_sk
FROM edw_core.tpolicy p 
JOIN edw_core.tpolicy_history ph ON ph.policy_sk = p.policy_sk
JOIN edw_core.tpolicy_transaction pt ON pt.policy_sk = p.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no
JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
LEFT JOIN edw_core.tauto_vehicle av ON av.auto_vehicle_sk = pt.item_sk
LEFT JOIN edw_core.tauto_vehicle_coverage avc ON avc.auto_vehicle_sk = av.auto_vehicle_sk
                                                and avc.policy_history_sk = ph.policy_history_sk
WHERE  1=1
   and p.policy_no = 'AU100220887-01'
   and p.risk_state_cd = 'MI'
   and ph.premium_amt <> 0
   and p.product_cd = 'AU'  -- excludes coverages that apply to other products, which might be included in the join
   and ic.internal_coverage_category_nm = 'Premium'  -- we only report on premium amounts
   and ic.internal_coverage_desc = 'Property Protection Insurance'
