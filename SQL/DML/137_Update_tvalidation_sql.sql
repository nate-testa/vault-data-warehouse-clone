update edw_core.tvalidation_sql
set validation_sql_desc='tclaim_transaction - missing claim payment transaction'
where validation_sql_desc='tclaim_trasnaction - missing claim payment transaction'


update edw_core.tvalidation_sql
set source_sql='select count(*) from edw_core.tclaim_feature a where aslob_sk is null and source_system_sk!=1 and claim_coverage_desc is not null and exists 
(select * from edw_core.tclaim_transaction b where a.claim_feature_sk=b.claim_feature_sk)'
where validation_sql_desc='tclaim_feature - aslob_sk is null but claim coverage exists'

update edw_core.tvalidation_sql
set source_sql='select count(*) from edw_core.tclaim_feature a where claim_coverage_desc is null and source_system_sk!=1 and exists 
(select * from edw_core.tclaim_transaction b where a.claim_feature_sk=b.claim_feature_sk)'
where validation_sql_desc='tclaim_feature - claim_coverage_desc is null'