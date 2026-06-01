IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_home_coverage'
      AND COLUMN_NAME = 'flood_zone'
)
BEGIN
    ALTER TABLE edw_core.tquote_home_coverage ADD flood_zone Varchar(255);
END;