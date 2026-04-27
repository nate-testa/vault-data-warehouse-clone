      IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_grpel_coverage'
      AND COLUMN_NAME = 'no_other_watercraft'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage ADD no_other_watercraft Varchar(255);
END;