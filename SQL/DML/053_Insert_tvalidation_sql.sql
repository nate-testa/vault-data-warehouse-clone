insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tpolicy_transaction - Invalid HSB coverage codes'  
		,' select count(*) from edw_core.tpolicy_transaction a,edw_core.tinternal_coverage b
            where a.internal_coverage_sk=b.internal_coverage_sk
            and b.internal_coverage_cd in (''System Protection'',''Service Line Admitted'',''Cyber Liability'')'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();  