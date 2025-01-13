IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'migration_coverage_mapping' and COLUMN_NAME = 'create_ts')
BEGIN
ALTER TABLE edw_stage.migration_coverage_mapping ADD create_ts datetime
END