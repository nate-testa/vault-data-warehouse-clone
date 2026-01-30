 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'thome_coverage'
      AND COLUMN_NAME = 'high_risk_wui_property_in'
)
BEGIN
    ALTER TABLE edw_core.thome_coverage
    ADD high_risk_wui_property_in  VARCHAR(255) NULL;
END;

 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'thome_coverage'
      AND COLUMN_NAME = 'effective_built_year'
)
BEGIN
    ALTER TABLE edw_core.thome_coverage
    ADD effective_built_year  VARCHAR(255) NULL;
END;
