IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tbroker'
      AND COLUMN_NAME = 'california_dba_nm'
)
BEGIN
    ALTER TABLE edw_core.tbroker ADD california_dba_nm VARCHAR(255) NULL;
END;