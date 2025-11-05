select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_pel_driver_incident%' order by etl_audit_sk desc;

-- truncate table [edw_core].[tquote_pel_driver_incident];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_driver_incident';
-- EXEC [edw_core].[sp_tquote_pel_driver_incident];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_driver_incident_wip';
-- EXEC [edw_core].[sp_tquote_pel_driver_incident_wip];

-- select count(1) from [edw_core].[tquote_pel_driver_incident];
-- select top 100 * from [edw_core].[tquote_pel_driver_incident];


