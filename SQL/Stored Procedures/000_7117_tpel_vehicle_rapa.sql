--tpel_vehicle
select top 100 * from edw_core.tetl_audit where process_nm like '%tpel_vehicle_rapa%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_tpel_vehicle_rapa');
select COUNT(1) from [edw_core].[tpel_vehicle_rapa];
select * from [edw_core].[tpel_vehicle_rapa];
select * from [edw_core].[tquote_pel_vehicle_rapa];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tpel_vehicle_rapa');
-- truncate table [edw_core].[tpel_vehicle_rapa];
-- EXEC [edw_core].[sp_tpel_vehicle_rapa];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tquote_pel_vehicle_rapa');
-- truncate table [edw_core].[tquote_pel_vehicle_rapa];
-- EXEC [edw_core].[sp_tquote_pel_vehicle_rapa];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tquote_pel_vehicle_rapa_wip');
-- EXEC [edw_core].[sp_tquote_pel_vehicle_rapa_wip];
