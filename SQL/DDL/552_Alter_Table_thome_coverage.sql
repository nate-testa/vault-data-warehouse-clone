IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'thome_coverage'					
AND COLUMN_NAME = 'wildfire_risk_score'					
) BEGIN ALTER TABLE edw_core.thome_coverage ADD wildfire_risk_score varchar(255) END 					
					
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'thome_coverage'					
AND COLUMN_NAME = 'wildfire_risk_class'					
) BEGIN ALTER TABLE edw_core.thome_coverage ADD wildfire_risk_class varchar(255) END 					
		
