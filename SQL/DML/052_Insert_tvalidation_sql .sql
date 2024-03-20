insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tpolicy - renewal policy termed as new'  
		,'select  count(*) FROM edw_core.tpolicy where policy_no like ''%-%'' and policy_term = ''new'' and source_system_sk <> 1'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate(); 