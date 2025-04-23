IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tclaim'					
AND COLUMN_NAME = 'coverage_confirmed_ts'					
) BEGIN ALTER TABLE edw_core.tclaim ADD coverage_confirmed_ts DATETIME END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tclaim'					
AND COLUMN_NAME = 'coverage_confirmed_by_nm'					
) BEGIN ALTER TABLE edw_core.tclaim ADD coverage_confirmed_by_nm  VARCHAR(255) END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tclaim'					
AND COLUMN_NAME = 'coverage_confirmed_in'					
) BEGIN ALTER TABLE edw_core.tclaim ADD coverage_confirmed_in VARCHAR(255) END
;

