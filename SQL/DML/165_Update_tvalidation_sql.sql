update edw_core.tvalidation_sql set source_sql = 
'select count(*) 
from edw_core.tclaim c, edw_core.tclaim_feature cf   where c.claim_sk = cf.claim_sk   and cf.source_system_sk = 5    
and c.policy_no not in (''AU9999VES'', ''AU9999VRE'', ''COV9999VES'', ''COV9999VRE'', ''FPP9999VES'', ''FPP9999VRE'',''FPP9998VRE,'')
and c.policy_no not like ''NFP%''  and cf.coverage_sk is null'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing coverage_sk'

update edw_core.tvalidation_sql set source_sql = 
'select count(*)
from edw_core.tclaim c, edw_core.tclaim_feature cf
where c.claim_sk = cf.claim_sk   and cf.source_system_sk = 5  
and c.policy_no not in (''AU9999VES'', ''AU9999VRE'', ''COV9999VES'', ''COV9999VRE'', ''FPP9999VES'', ''FPP9999VRE'',''FPP9998VRE'')
and cf.product_sk != 4   and cf.item_sk is null'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing item_sk'