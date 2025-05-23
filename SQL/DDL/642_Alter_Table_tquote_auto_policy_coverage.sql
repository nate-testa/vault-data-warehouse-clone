IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_policy_coverage'					
AND COLUMN_NAME = 'consent_to_rate_otccoll'					
) BEGIN ALTER TABLE edw_core.tquote_auto_policy_coverage ADD consent_to_rate_otccoll VARCHAR(255) END ; 