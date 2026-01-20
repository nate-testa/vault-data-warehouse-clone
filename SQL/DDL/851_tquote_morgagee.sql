IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_mortgagee'
      AND COLUMN_NAME = 'mortgagee_nm'
)
BEGIN
    ALTER TABLE edw_core.tquote_mortgagee ALTER COLUMN mortgagee_nm VARCHAR(2000) NULL;
END;