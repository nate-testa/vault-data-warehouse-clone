IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'agreed_value_coverage_in'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD agreed_value_coverage_in VARCHAR(255) END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'flood_deductible_pc'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD flood_deductible_pc VARCHAR(255) END
;