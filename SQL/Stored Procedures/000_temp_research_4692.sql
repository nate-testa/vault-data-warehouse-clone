-- 'AU100037388'  
WITH tbl AS (
   SELECT 
         p.policy_no
      , p.risk_state_cd
   /*     , p.effective_dt
      , p.policy_sk
   */    , ph.policy_history_sk
      , ph.transaction_effective_dt
      --  , ph.transaction_ts
      -- , ph.transaction_type
      , ph.transaction_seq_no
       , pt.premium_amt
      , pt.vehicle_coverage_sk
      , ic.internal_coverage_desc
      , ic.internal_coverage_sk
      , av.vehicle_model_year
      , av.vehicle_make
      , av.vehicle_model
      , av.vehicle_vin 
      , avc.auto_vehicle_coverage_sk
      , avc.auto_vehicle_sk
      , ic.aslob_cd
      , ic.internal_coverage_category_nm
      ,pt.source_system_sk
   FROM edw_core.tpolicy p 
   JOIN edw_core.tpolicy_history ph ON ph.policy_sk = p.policy_sk
   JOIN edw_core.tpolicy_transaction pt ON pt.policy_sk = p.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no
   JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
   LEFT JOIN edw_core.tauto_vehicle av ON av.auto_vehicle_sk = pt.item_sk
   LEFT JOIN edw_core.tauto_vehicle_coverage avc ON avc.auto_vehicle_sk = av.auto_vehicle_sk
                                                   and avc.policy_history_sk = ph.policy_history_sk
   WHERE  1=1
      and p.policy_no LIKE 'AU100028533-01'  -- testing only
      and ph.premium_amt <> 0
      and p.product_cd = 'AU'  -- excludes coverages that apply to other products, which might be included in the join
      -- and ic.internal_coverage_category_nm = 'Premium'  -- we only report on premium amounts
         --  and ic.internal_coverage_desc LIKE 'Auto%Death%'
)

select 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   internal_coverage_desc, 
   sum(premium_amt) 
from tbl
where vehicle_vin = '1GYS4GKL2NR156499'
group by 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   internal_coverage_desc


;

SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100028533-01';
SELECT * FROM edw_core.tpolicy_history WHERE policy_no = 'AU100028533-01';
SELECT DISTINCT item_sk, internal_coverage_sk FROM edw_core.tpolicy_transaction WHERE policy_sk = 102947;
SELECT * FROM edw_core.tinternal_coverage WHERE internal_coverage_sk IN (25,97,104,142,223,235,243,339);
SELECT * FROM edw_core.tauto_vehicle where auto_vehicle_sk in (0,14537,14538,14539,14540,14541,14542);
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE policy_history_sk IN (221438,10830,84551,186039);

select * from edw_core.tsource_system;

SELECT * FROM edw_core.tpolicy_transaction pt 
JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
WHERE pt.policy_sk = 26686
;


SELECT COUNT(1) FROM edw_core.tauto_vehicle_coverage WHERE auto_garage_location_sk IS NULL;--0


select *
from edw_core.tquote_home_location
where quote_no = 'HO200028240'
;

select *
from edw_stage.AccountTransaction
where PolicyNumber = 'HO200028240'
;