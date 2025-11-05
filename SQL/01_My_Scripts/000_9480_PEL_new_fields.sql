select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_tpel_coverage','sp_tquote_pel_coverage','sp_tquote_pel_coverage_wip');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tpel_coverage','sp_tquote_pel_coverage','sp_tquote_pel_coverage_wip');
-- EXEC sp_help '[edw_core].[claim_clue_auto_feed]';

-- TRUNCATE TABLE [edw_core].[tpel_coverage];
-- TRUNCATE TABLE [edw_core].[tquote_pel_coverage];

SELECT COUNT(1) FROM [edw_core].[tpel_coverage];
SELECT COUNT(1) FROM [edw_core].[tquote_pel_coverage];

-- EXEC [edw_core].[sp_tquote_pel_coverage_wip];
-- EXEC [edw_core].[sp_tquote_pel_coverage];
-- EXEC [edw_core].[sp_tpel_coverage];

----------------------------------------------------------------------------