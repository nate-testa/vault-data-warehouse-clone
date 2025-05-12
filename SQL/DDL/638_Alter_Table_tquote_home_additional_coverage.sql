IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_additional_coverage'					
AND COLUMN_NAME = 'all_peril_roof_covering_coverage_CW_in'					
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD all_peril_roof_covering_coverage_CW_in VARCHAR(255) END ; 
