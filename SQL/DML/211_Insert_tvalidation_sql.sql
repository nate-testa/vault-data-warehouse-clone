INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Clue Auto - ClaimType contains CO and CP' ,
'select count(*) from (
select
	cf.claim_no 
from
	edw_core.tclaim_feature cf
	where cf.product_sk  = 3 
	and cf.claim_coverage_desc  in  (''Collision'', ''Comprehensive'') 
	group by cf.claim_no 
	having count(distinct cf.claim_coverage_desc) > 1
) dup_claims' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
       

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Clue Auto - ClaimType CP has at_fault_indicator = ''A''' ,
'select
	count(*)
from
	edw_core.tclaim_feature cf
inner join edw_core.tclaim c 
on
	cf.claim_sk = c.claim_sk
where
	cf.claim_coverage_desc = ''Comprehensive''
	and c.fault_decision = ''insured''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;