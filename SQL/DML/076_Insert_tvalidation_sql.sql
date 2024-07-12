insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'thome_coverage - Data standardization $0 deductible amount' as validation_sql_desc
		,'select count(*) from edw_core.thome_coverage
where 
wildfire_deductible in (''0'',''0.00'') or
hurricane_deductible in (''0'',''0.00'') or
wind_or_hailstorm_deductible in (''0'',''0.00'') or
hurricane_or_named_storm_deductible in (''0'',''0.00'') or
tornado_or_hailstorm_deductible in (''0'',''0.00'') or
named_storm_deductible in (''0'',''0.00'') or
water_deductible in (''0'',''0.00'') or
wildfire_deductible in (''0'',''0.00'') or
aop_deductible in (''0'',''0.00'')' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;

insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'thome_coverage - Data standardization deductible amount format issues' as validation_sql_desc
		,'select count(*) from edw_core.thome_coverage
where 
(
	CHARINDEX('','',wildfire_deductible) > 0
	or CHARINDEX(''$'',wildfire_deductible) > 0
	or wildfire_deductible = ''-''
	or SUBSTRING(wildfire_deductible,charindex(''.'',wildfire_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',wildfire_deductible) > 0
)
or
(
	CHARINDEX('','',hurricane_deductible) > 0
	or CHARINDEX(''$'',hurricane_deductible) > 0
	or hurricane_deductible = ''-''
	or SUBSTRING(hurricane_deductible,charindex(''.'',hurricane_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',hurricane_deductible) > 0
)
or
(
	CHARINDEX('','',wind_or_hailstorm_deductible) > 0
	or CHARINDEX(''$'',wind_or_hailstorm_deductible) > 0
	or wind_or_hailstorm_deductible = ''-''
	or SUBSTRING(wind_or_hailstorm_deductible,charindex(''.'',wind_or_hailstorm_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',wind_or_hailstorm_deductible) > 0
)
or
(
	CHARINDEX('','',hurricane_or_named_storm_deductible) > 0
	or CHARINDEX(''$'',hurricane_or_named_storm_deductible) > 0
	or hurricane_or_named_storm_deductible = ''-''
	or SUBSTRING(hurricane_or_named_storm_deductible,charindex(''.'',hurricane_or_named_storm_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',hurricane_or_named_storm_deductible) > 0
)


or
(
	CHARINDEX('','',tornado_or_hailstorm_deductible) > 0
	or CHARINDEX(''$'',tornado_or_hailstorm_deductible) > 0
	or tornado_or_hailstorm_deductible = ''-''
	or SUBSTRING(tornado_or_hailstorm_deductible,charindex(''.'',tornado_or_hailstorm_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',tornado_or_hailstorm_deductible) > 0
)

or
(
	CHARINDEX('','',named_storm_deductible) > 0
	or CHARINDEX(''$'',named_storm_deductible) > 0
	or named_storm_deductible = ''-''
	or SUBSTRING(named_storm_deductible,charindex(''.'',named_storm_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',named_storm_deductible) > 0
)

or
(
	CHARINDEX('','',water_deductible) > 0
	or CHARINDEX(''$'',water_deductible) > 0
	or water_deductible = ''-''
	or SUBSTRING(water_deductible,charindex(''.'',water_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',water_deductible) > 0
)

or
(
	CHARINDEX('','',wildfire_deductible) > 0
	or CHARINDEX(''$'',wildfire_deductible) > 0
	or wildfire_deductible = ''-''
	or SUBSTRING(wildfire_deductible,charindex(''.'',wildfire_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',wildfire_deductible) > 0
)

or
(
	CHARINDEX('','',aop_deductible) > 0
	or CHARINDEX(''$'',aop_deductible) > 0
	or aop_deductible = ''-''
	or SUBSTRING(aop_deductible,charindex(''.'',aop_deductible)+1,100) = ''00''
	or CHARINDEX(''%'',aop_deductible) > 0
)' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;