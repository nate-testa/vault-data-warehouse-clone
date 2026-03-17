IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy'
      AND COLUMN_NAME = 'marine_boat_yacht_broker_nm'
)
BEGIN
    ALTER TABLE edw_core.tpolicy ADD marine_boat_yacht_broker_nm VARCHAR(256) NULL;
END;
 
