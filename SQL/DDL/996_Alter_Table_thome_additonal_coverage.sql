 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'thome_additional_coverage'
      AND COLUMN_NAME = 'wind_hail_roof_covering_schedule_in'
)
BEGIN
    ALTER TABLE edw_core.thome_additional_coverage ADD wind_hail_roof_covering_schedule_in Varchar(255);
END;