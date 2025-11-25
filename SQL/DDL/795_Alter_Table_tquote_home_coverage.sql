IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_coverage'					
AND COLUMN_NAME = 'prior_claims_in'					
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD prior_claims_in VARCHAR(255) END ; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_coverage'					
AND COLUMN_NAME = 'prior_claims_over_2500_in'					
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD prior_claims_over_2500_in VARCHAR(255) END ; 