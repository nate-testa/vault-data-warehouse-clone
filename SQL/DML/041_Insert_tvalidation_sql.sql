insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tauto_vehicle - duplicate vehicle VIN' 
		,'select count(*) from (
			select policy_no, effective_dt, veh.vehicle_vin  from edw_core.tauto_vehicle veh 
			where NULLIF(trim(vehicle_vin),'''') is not null
			group by policy_no, effective_dt, veh.vehicle_vin 
			having count(*) > 1) a'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate(); 