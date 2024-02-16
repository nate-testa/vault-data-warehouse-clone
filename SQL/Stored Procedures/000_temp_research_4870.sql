-- metal_product_fieldname_datafix
-- Product- 
-- Home
-- Auto
-- PEL
-- Lux

SELECT * FROM edw_core.tsource_system;
SELECT * FROM edw_core.tpolicy WHERE policy_no like 'HO100237820-03';
SELECT * FROM edw_core.tpolicy_history WHERE policy_no like 'HO100237820-03' ORDER BY policy_no, transaction_seq_no;
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk in (63172,55116,49860);
SELECT * FROM edw_core.thome_location WHERE policy_no IN ('HOX10010024');


select policy_no , address_line_1 ,state_cd , county_nm  
-- select *
from vault_edw.edw_core.thome_location
where policy_no IN (
    'HOX10010204'
    )
;

--User QRY
select transaction_desc , c.dwelling_limit_amt , p.policy_no ,
h.transaction_effective_dt ,cast(h.transaction_ts as date) as processed_dt,
h.transaction_seq_no 
from edw_core.tpolicy p
left join edw_core.tpolicy_history h on p.policy_sk = h.policy_sk 
left join edw_core.thome_coverage c on c.policy_history_sk = h.policy_history_sk 
where p.policy_no like 'HO100237820%'
order by p.policy_no , h.transaction_effective_dt  , h.transaction_ts
;


--Cruce final para actualizar data
SELECT acct.PolicyNumber AS policy_no, acct.EffectiveDate AS effective_dt, acct.policychangenumber AS transaction_seq_no, acctvof.Id AS acctvof_Id, acctvof.VersionObjectId, acctvof.Field AS acctvof_Field, acctvof.[Value] AS METAL_county_nm, hl.county_lu AS CORRECT_VALUE_county_nm
-- INTO [edw_temp].[metal_Home_RiskAddressCounty_datafix]
FROM edw_temp.av2_home_location_county hl
INNER JOIN [edw_stage].[AccountTransaction] acct ON acct.PolicyNumber = hl.base_policy_no
INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acct.Id = acctv.AccountTransactionId
INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 1=1
    AND acctvof.Field = 'RiskAddressCounty'
ORDER BY hl.base_policy_no
;

SELECT TOP 10 * FROM edw_stage.AccountTransactionVersion
;

SELECT * FROM [edw_temp].[metal_Home_RiskAddressCounty_datafix]
;

