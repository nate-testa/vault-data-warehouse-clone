-- tpolicy_transaction - item_sk= 0 for AU
update edw_core.tvalidation_sql 
set source_sql = 
'select count(*) from 
edw_core.tpolicy_transaction pt 
inner join edw_core.tdate d on pt.effective_dt_sk = d.date_sk
where product_sk = 3 and isnull(item_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1   
and internal_coverage_sk not in 
(
	select internal_coverage_sk from edw_core.tinternal_coverage         
	where internal_coverage_cd in (''Automobile Death Indemnity and Disability Income'',
''Auto Death Disability'',''Emergency Living Expense'',''Equipment Manufacturer Parts Enhancement'',
''Full Glass Coverage Enhancement'',''Multiple Policy Deductible Enhancement'',''Stated Value Enhancement'')
)
and d.actual_dt >= ''2025-01-01''',
target_sql = 'select 25'
where
	validation_sql_desc= 'tpolicy_transaction - item_sk= 0 for AU'

-- tpolicy_transaction - policies having vehicle_coverage_sk = 0 for AU
update edw_core.tvalidation_sql
set source_sql = 
'select count(distinct pol.policy_sk) 
from edw_core.tpolicy_transaction tr,edw_core.tpolicy pol
where pol.policy_sk = tr.policy_sk and product_sk = 3         
and isnull(vehicle_coverage_sk,0) = 0 and tax_fee_surcharge_sk = 0 and pol.source_system_sk <> 1
and pol.effective_dt >= ''2025-01-01''  
and isnull(tr.item_sk,0) != 0
and internal_coverage_sk not in 
(
	select internal_coverage_sk from edw_core.tinternal_coverage
	where internal_coverage_cd in 
	(
		''Automobile Death Indemnity and Disability Income'', 
		''Auto Death Disability'',''Emergency Living Expense'',''Equipment Manufacturer Parts Enhancement'',
		''Full Glass Coverage Enhancement'',''Multiple Policy Deductible Enhancement'',''Stated Value Enhancement'')
)',
target_sql = 'select 0'
where
	validation_sql_desc= 'tpolicy_transaction - policies having vehicle_coverage_sk = 0 for AU'

-- tpolicy_transaction - LUX - collection_class_type_sk = 0

update edw_core.tvalidation_sql
set source_sql = 
'select count(*) 
from 
edw_core.tpolicy_transaction a 
inner join edw_core.tpolicy pol on a.policy_sk = pol.policy_sk 
inner join edw_core.tinternal_coverage ic on a.internal_coverage_sk = ic.internal_coverage_sk  
where 
isnull(collection_class_type_sk,0) = 0  and tax_fee_surcharge_sk = 0      
and 
(
	product_sk = 2  or (a.source_system_sk = 4 and product_sk in (1,5) 
	and ic.internal_coverage_cd = ''Lux'')  
) and pol.migrated_in = ''No''
and pol.effective_dt >= ''2025-01-01''',
target_sql = 'select 0'
where
	validation_sql_desc= 'tpolicy_transaction - LUX - collection_class_type_sk = 0'
