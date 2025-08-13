IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_additional_coverage'					
AND COLUMN_NAME = 'defense_coverage_within_limits_in'					
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD defense_coverage_within_limits_in varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_additional_coverage'					
AND COLUMN_NAME = 'wind_sublimit_in'					
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD wind_sublimit_in varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_home_additional_coverage'					
AND COLUMN_NAME = 'wind_sublimit_value_amt'					
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD wind_sublimit_value_amt varchar(255) END

