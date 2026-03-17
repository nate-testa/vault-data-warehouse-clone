IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy_history'
      AND COLUMN_NAME = 'marine_boat_yacht_producer_nm'
)
BEGIN
    ALTER TABLE edw_core.tpolicy_history ADD marine_boat_yacht_producer_nm VARCHAR(256) NULL;
END;
 