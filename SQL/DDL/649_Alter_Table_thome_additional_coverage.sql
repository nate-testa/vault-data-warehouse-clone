IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'thome_additional_coverage'					
AND COLUMN_NAME = 'caddy_grade'					
) BEGIN ALTER TABLE edw_core.thome_additional_coverage ADD caddy_grade VARCHAR(255) END ; 