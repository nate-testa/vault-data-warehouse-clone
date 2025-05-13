IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_pel_coverage'					
AND COLUMN_NAME = 'auto_liability_exclusion_in'					
) BEGIN ALTER TABLE edw_core.tquote_pel_coverage ADD auto_liability_exclusion_in VARCHAR(255) END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_pel_coverage'					
AND COLUMN_NAME = 'recreational_watercraft_exclusion_in'					
) BEGIN ALTER TABLE edw_core.tquote_pel_coverage ADD recreational_watercraft_exclusion_in VARCHAR(255) END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_pel_coverage'					
AND COLUMN_NAME = 'recreational_motorvehicle_exclusion_in'					
) BEGIN ALTER TABLE edw_core.tquote_pel_coverage ADD recreational_motorvehicle_exclusion_in VARCHAR(255) END ; 