IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tpolicy_history'					
AND COLUMN_NAME = 'insurance_score_source'					
) BEGIN ALTER TABLE edw_core.tpolicy_history ADD insurance_score_source VARCHAR(255) END ; 