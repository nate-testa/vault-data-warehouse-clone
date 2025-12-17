update edw_core.tvalidation_sql
set source_sql='select count(*) from edw_core.tclaim c, edw_core.tclaim_feature cf, edw_core.tcustomer cus 
where c.claim_sk = cf.claim_sk and cf.source_system_sk = 5 
AND cus.customer_id = c.customer_id AND cus.customer_nm <> ''Vault Insurance''
and c.policy_no not like ''NFP%'' and cf.coverage_sk is null'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing coverage_sk';
