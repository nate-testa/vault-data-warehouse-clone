insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tquote - incorrect quote term' as validation_sql_desc
		,'select count(*) from edw_core.tquote where quote_term=''New'' and quote_no like ''%-%''' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;