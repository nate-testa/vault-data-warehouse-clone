IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_history'
      AND COLUMN_NAME = 'primary_home_credit_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_history ADD primary_home_credit_in VARCHAR(255) NULL;
END;