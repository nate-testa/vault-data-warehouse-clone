IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tmortgagee'
      AND COLUMN_NAME = 'mortgagee_nm'
)
BEGIN
    ALTER TABLE edw_core.tmortgagee ALTER COLUMN mortgagee_nm VARCHAR(2000) NULL;
END;