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
   auto_vehicle_sk,
   internal_coverage_sk,
   internal_coverage_desc, 
   sum(premium_amt) 
from tbl
where vehicle_vin = '1GYS4GKL2NR156499'
group by 
   -- transaction_seq_no, 
   -- source_system_sk, 
   vehicle_model, 
   vehicle_vin, 
   auto_vehicle_sk,
   internal_coverage_sk,
   internal_coverage_desc


;

SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100028533-01';
SELECT * FROM edw_core.tpolicy_history WHERE policy_no = 'AU100028533-01';
SELECT distinct internal_coverage_sk FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171; and item_sk = 1409 and internal_coverage_sk = 223 order by transaction_seq_no;
SELECT * FROM edw_core.tinternal_coverage WHERE internal_coverage_sk IN (25,57,100,103,122,197,209,287);
SELECT * FROM edw_core.tauto_vehicle where auto_vehicle_sk in (0,1409,4103,4104,13264,13265,18979);
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE policy_history_sk IN (221438,10830,84551,186039);

select * from edw_core.tsource_system;

SELECT * FROM edw_core.tpolicy_transaction pt 
JOIN edw_core.tinternal_coverage ic ON ic.internal_coverage_sk = pt.internal_coverage_sk
WHERE pt.policy_sk = 26686
;


SELECT COUNT(1) FROM edw_core.tauto_vehicle_coverage WHERE auto_garage_location_sk IS NULL;--0

SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171;

--Changes

select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransaction where PolicyNumber = 'AU100028533-01' and PolicyChangeNumber = 2;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808';

--**UPDATES**
--biPrem - Bodily Injury update premium_amt(PremiumDeltaProRated) from -265 to -266
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 1409 and internal_coverage_sk = 25 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage, * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-265' and id = 2954937;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '-266', CommissionDeltaProRated = -266*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-265' and id = 2954937;

--cdPrem - collision update premium_amt(PremiumDeltaProRated) from -202 to -854
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 1409 and internal_coverage_sk = 209 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage, * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-202' and id = 2954938;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '-854', CommissionDeltaProRated = -854*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-202' and id = 2954938;

--medPrem - Medical Payments update premium_amt(PremiumDeltaProRated) from -23 to -22
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 1409 and internal_coverage_sk = 122 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-23' and id = 2954934;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '-22', CommissionDeltaProRated = -22*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-23' and id = 2954934;

--otcPrem - Other Than Collision update premium_amt(PremiumDeltaProRated) from 129 to 117 and premium_amt from -54 to -285
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 1409 and internal_coverage_sk = 100 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '129' and id = 2954942;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-54' and id = 2954932;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '117', CommissionDeltaProRated = 117*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '129' and id = 2954942;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '-285', CommissionDeltaProRated = -285*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-54' and id = 2954932;

--pdPrem - Property Damage update premium_amt(PremiumDeltaProRated) from -86 to -87
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 1409 and internal_coverage_sk = 197 order by transaction_seq_no;
select (CommissionDeltaProRated/PremiumDeltaProRated) CommisionPercentage,  * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-86' and id = 2954935;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '-87', CommissionDeltaProRated = -87*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '-86' and id = 2954935;

--otcPrem - Other Than Collision update premium_amt(PremiumDeltaProRated) from 0 to 49
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 108171 and item_sk = 4104 and internal_coverage_sk = 100 order by transaction_seq_no;
select * from edw_stage.AccountTransactionCoveragePremium where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '0' and id = 2954941;
-- update edw_stage.AccountTransactionCoveragePremium set PremiumDeltaProRated = '49', CommissionDeltaProRated = 49*0.12 where AccountTransactionId = 'fcbb2ecc-504f-4550-8363-5d7a9d742808' and PremiumDeltaProRated = '0' and id = 2954941;

