delete from edw_core.tvalidation_sql
where validation_sql_desc = 'tpolicy - dupes on policy_no';

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - dupes on policy_no', 
		'select count(*) from
		(
		select policy_no from edw_core.tpolicy
		group by policy_no
		having count(*)>1
		) a' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;

update edw_core.tvalidation_sql
set source_sql = 'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and isnull(item_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1 
				  and internal_coverage_sk not in (select internal_coverage_sk from edw_core.tinternal_coverage 
				  where internal_coverage_cd in (''Automobile Death Indemnity and Disability Income'',''Auto Death Disability'',''Emergency Living Expense'',''Equipment Manufacturer Parts Enhancement'',''Full Glass Coverage Enhancement'',''Multiple Policy Deductible Enhancement'',''Stated Value Enhancement''))'
where validation_sql_desc = 'tpolicy_transaction - item_sk= 0 for AU';

update edw_core.tvalidation_sql
set source_sql = 'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and isnull(vehicle_coverage_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1 
				  and internal_coverage_sk not in (select internal_coverage_sk from edw_core.tinternal_coverage 
				  where internal_coverage_cd in (''Automobile Death Indemnity and Disability Income'',''Auto Death Disability'',''Emergency Living Expense'',''Equipment Manufacturer Parts Enhancement'',''Full Glass Coverage Enhancement'',''Multiple Policy Deductible Enhancement'',''Stated Value Enhancement''))'
where validation_sql_desc = 'tpolicy_transaction - vehicle_coverage_sk = 0 for AU';

update edw_core.tvalidation_sql
set source_sql = 'tpolicy_transaction - internal_coverage_sk = 0'
where validation_sql_desc = 'tpolicy_transaction - internal_isnull(coverage_sk,0) = 0';