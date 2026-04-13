IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'thome_coverage'
      AND COLUMN_NAME = 'roof_geometry_api'
)
BEGIN
    ALTER TABLE edw_core.thome_coverage ADD roof_geometry_api varchar(255) ;
END;
 