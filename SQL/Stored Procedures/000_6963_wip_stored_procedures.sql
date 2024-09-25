--*** SPs to change ***--
-- sp_tquote_auto_driver_incident_wip
-- sp_tquote_auto_driver_wip
-- sp_tquote_auto_garage_location_wip
-- sp_tquote_auto_policy_coverage_wip
-- sp_tquote_auto_vehicle_coverage_rapa_wip
-- sp_tquote_auto_vehicle_coverage_wip
-- sp_tquote_auto_vehicle_wip
--*** SPs to change ***--

select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_auto_%wip%' order by etl_audit_sk desc;

update edw_core.tetl_control 
set last_source_extract_ts = '1900-01-01 00:00:00' 
where process_nm in (
    'sp_tquote_auto_driver_incident_wip',
    'sp_tquote_auto_driver_wip',
    'sp_tquote_auto_garage_location_wip',
    'sp_tquote_auto_policy_coverage_wip',
    'sp_tquote_auto_vehicle_coverage_rapa_wip',
    'sp_tquote_auto_vehicle_coverage_wip',
    'sp_tquote_auto_vehicle_wip'
    )
;

-- truncate table edw_core.tquote_auto_driver_incident;
-- truncate table edw_core.tquote_auto_driver;
-- truncate table edw_core.tquote_auto_garage_location;
-- truncate table edw_core.tquote_auto_policy_coverage;
-- truncate table edw_core.tquote_auto_vehicle_coverage_rapa;
-- truncate table edw_core.tquote_auto_vehicle_coverage;
-- delete from edw_core.tquote_auto_vehicle;

-- EXEC edw_core.sp_tquote_auto_vehicle_wip;
-- EXEC edw_core.sp_tquote_auto_driver_wip;
-- EXEC edw_core.sp_tquote_auto_driver_incident_wip;
-- EXEC edw_core.sp_tquote_auto_garage_location_wip;
-- EXEC edw_core.sp_tquote_auto_policy_coverage_wip;
-- EXEC edw_core.sp_tquote_auto_vehicle_coverage_rapa_wip;
-- EXEC edw_core.sp_tquote_auto_vehicle_coverage_wip;



select 'tquote_auto_driver_incident' as tbl_nm, count(1) as ct from edw_core.tquote_auto_driver_incident
union all select 'tquote_auto_driver' as tbl_nm, count(1) as ct from edw_core.tquote_auto_driver
union all select 'tquote_auto_garage_location' as tbl_nm, count(1) as ct from edw_core.tquote_auto_garage_location
union all select 'tquote_auto_policy_coverage' as tbl_nm, count(1) as ct from edw_core.tquote_auto_policy_coverage
union all select 'tquote_auto_vehicle_coverage_rapa' as tbl_nm, count(1) as ct from edw_core.tquote_auto_vehicle_coverage_rapa
union all select 'tquote_auto_vehicle_coverage' as tbl_nm, count(1) as ct from edw_core.tquote_auto_vehicle_coverage
union all select 'tquote_auto_vehicle' as tbl_nm, count(1) as ct from edw_core.tquote_auto_vehicle
;

