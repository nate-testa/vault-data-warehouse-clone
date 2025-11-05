select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_property_feed');
-- EXEC sp_help '[edw_integration].[claim_clue_property_feed]';

SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];--21782

-- SELECT * INTO [edw_temp].[claim_clue_property_feed_bk_20250911] FROM [edw_integration].[claim_clue_property_feed];
SELECT COUNT(1) FROM [edw_temp].[claim_clue_property_feed_bk_20250911];--21782

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_property_feed');
-- TRUNCATE TABLE [edw_integration].[claim_clue_property_feed];
-- EXEC [edw_core].[sp_claim_clue_property_feed];

SELECT COUNT(1) FROM [edw_integration].[claim_clue_property_feed];--4107