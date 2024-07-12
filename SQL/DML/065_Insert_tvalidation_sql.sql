insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tquote_history - Dupes on latest_transaction_in'  
		,'select count(*) from edw_core.tquote_history
		  where quote_no in (select quote_no from edw_core.tquote_history where latest_transaction_in = ''Y'' group by quote_no having count(*) > 1) '
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();   