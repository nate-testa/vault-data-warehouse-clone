select top 100 * from edw_core.tetl_audit where process_nm like 'sp_tquote_auto_driver%' order by etl_audit_sk desc;
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm = 'sp_tquote_auto_driver';
-- truncate table [edw_core].[tquote_auto_driver];
-- EXEC [edw_core].[sp_tquote_auto_driver];
-- EXEC [edw_core].[sp_tquote_auto_driver_wip];
select count(1) from [edw_core].[tquote_auto_driver];
select * from [edw_core].[tquote_auto_driver];

