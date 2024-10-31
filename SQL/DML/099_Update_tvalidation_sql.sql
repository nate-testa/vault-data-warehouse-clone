update edw_core.tvalidation_sql 
set target_sql = 'select 0',
	source_sql =  'select count(*) from edw_core.tpolicy_transaction a inner join edw_core.tpolicy pol on a.policy_sk = pol.policy_sk inner join edw_core.tinternal_coverage ic on a.internal_coverage_sk = ic.internal_coverage_sk  where isnull(collection_class_type_sk,0) = 0  and tax_fee_surcharge_sk = 0      and (product_sk = 2  or (a.source_system_sk = 4 and product_sk in (1,5) and ic.internal_coverage_cd = ''Lux'')  ) and pol.migrated_in = ''No'''
where validation_sql_desc = 'tpolicy_transaction - LUX - collection_class_type_sk = 0';

update edw_core.tvalidation_sql 
set active_in = 'N'
where validation_sql_desc = 'tpolicy_history - transactions after policy expiry'; 

update edw_core.tvalidation_sql 
set source_sql =  'select count(*) from (  select PolicyNumber,EffectiveDate,PolicyChangeNumber  from edw_stage.AccountTransaction   where state=''ISSUED'' and PolicyNumber is not null  group by PolicyNumber,EffectiveDate,PolicyChangeNumber  having count(*)>1) a'
where validation_sql_desc = 'Metal Validation - AccountTransaction - Duplicates';

update edw_core.tvalidation_sql 
set source_sql =  'select count(distinct broker_id) from      (select broker_id,product_nm,state_cd,program_type,team_member_type,count(*) cnt from edw_core.tbroker_vault_team       group by broker_id,product_nm,state_cd,program_type,team_member_type      having count(*)>1      )a'
where validation_sql_desc = 'tbroker_vault_team - dupes';