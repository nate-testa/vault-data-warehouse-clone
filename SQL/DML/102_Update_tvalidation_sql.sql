update edw_core.tvalidation_sql
set target_sql = 'select 4',
	source_sql = 'select count(*) from (     
				  select   tr.policy_sk      
				  from edw_core.tpolicy_transaction tr, edw_core.tpolicy pol     
				  where tr.policy_sk=pol.policy_sk and pol.migrated_in=''No''     
				  group by  tr.policy_sk      
				  having sum(tr.premium_amt)<0) a'
where validation_sql_desc = 'tpolicy_transaction - negative total prmeium_amt';