update edw_core.tvalidation_sql
set source_sql = 'select count(*) from
(  
	select
		cf.claim_no
	from   
		edw_core.tclaim_feature cf
	where 
	cf.source_system_sk = 5
	and cf.product_sk  = 3
	and cf.claim_coverage_desc  in  (''Collision'', ''Comprehensive'')
group by cf.claim_no    
having count(distinct cf.claim_coverage_desc) > 1  ) dup_claims'
where
	validation_sql_desc = 'Clue Auto - ClaimType contains CO and CP'