insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tpolicy_history - transactions after policy expiry' as validation_sql_desc
		,'select count(*) from edw_core.tpolicy_history
		where datediff("d",expiration_dt,cast(transaction_ts as date)) > 0
		and datediff("d",cast(transaction_ts as date),getdate()) <= 30 ' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;