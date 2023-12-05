insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - uw_company_nm is null', 
		'select count(*) from edw_core.tpolicy where uw_company_nm is null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts;
	
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - program_type is null', 
		'select count(*) from edw_core.tpolicy where program_type is null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts;

update edw_core.tvalidation_sql
set source_sql = 'SELECT count(*) from edw_core.tpolicy_transaction where isnull(policy_transaction_type_sk,0) = 0 and source_system_sk!=1'
where validation_sql_desc = 'tpolicy_transaction - policy_transaction_type_sk = 0';