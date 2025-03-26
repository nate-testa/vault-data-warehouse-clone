update edw_core.tvalidation_sql
set 
source_sql = 'select count(*) from edw_core.tpolicy pol where not exists (select 1 from edw_core.tpolicy_transaction tr where tr.policy_sk=pol.policy_sk) and customer_id not like ''%LIT%'''
where validation_sql_desc = 'tpolicy_transaction - Missing transactions for policies in tpolicy';

update edw_core.tvalidation_sql
set 
source_sql = 'select count(distinct broker_id) from (select broker_id,product_nm,state_cd,program_type,team_member_type,count(*) cnt from edw_core.tbroker_vault_team where product_nm<>''Marine Boat & Yacht'' group by broker_id,product_nm,state_cd,program_type,team_member_type having count(*)>1)a'
where validation_sql_desc = 'tbroker_vault_team - dupes';

update edw_core.tvalidation_sql
set 
target_sql = 'select 3'
where validation_sql_desc = 'Snapsheet Validation- Cancelled approved reserves/payments';