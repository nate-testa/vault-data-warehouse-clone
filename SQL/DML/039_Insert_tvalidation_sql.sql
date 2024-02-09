insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'thome_coverage - wind_derived_deductible - unexpected characters' 
		,'select count(*) from edw_core.thome_coverage where wind_derived_deductible LIKE ''%[%]%'' or wind_derived_deductible like ''%N/A-AOP%'''
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();

insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tcatastrophe - alpha characters in CAT code' 
		,'select count(*) from edw_core.tcatastrophe where catastrophe_cd LIKE ''CAT%'''
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();

insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tpolicy_transaction - negative total prmeium_amt' 
		,'	select count(*) from (
			select   tr.policy_sk 
			from edw_core.tpolicy_transaction tr, edw_core.tpolicy pol
			where tr.policy_sk=pol.policy_sk  
			group by  tr.policy_sk 
			having sum(tr.premium_amt)<0) a'
		,'select 114'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();

update edw_core.tvalidation_sql
set validation_sql_desc = 'tpolicy_transaction - internal_coverage_sk = 0'
where validation_sql_desc = 'tpolicy_transaction - internal_isnull(coverage_sk,0) = 0';

update edw_core.tvalidation_sql
set source_sql = 'select count(*) from edw_core.tpolicy_transaction where internal_coverage_sk = 0'
where validation_sql_desc = 'tpolicy_transaction - internal_coverage_sk = 0';