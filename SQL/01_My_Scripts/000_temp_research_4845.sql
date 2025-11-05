-- metal_product_fieldname_datafix
-- Product- 
-- Home
-- Auto
-- PEL
-- Lux

SELECT * FROM edw_core.tsource_system;
SELECT * FROM edw_core.tpolicy WHERE policy_no = 'HOX10010024';
SELECT * FROM edw_core.thome_location WHERE policy_no IN ('HOX10010024');


select policy_no , address_line_1 ,state_cd , county_nm  
-- select *
from vault_edw.edw_core.thome_location
where policy_no IN (
    'HOX10010024',
    'HOX10010489',
    'HOX10013146',
    'HO100194817',
    'HOX10010968',
    'HOX10005329',
    'HOX10001999',
    'HOX10010197',
    'HOX10006333',
    'HOX10004992',
    'HOX10008016',
    'HO100198871',
    'HOX10011768',
    'HOX10012134',
    'HOX10011403',
    'HO100201673',
    'HO100193667',
    'HOX10002893',
    'HO100032601',
    'HO100204853',
    'HO100201698',
    'HOX10010204'
    )
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

