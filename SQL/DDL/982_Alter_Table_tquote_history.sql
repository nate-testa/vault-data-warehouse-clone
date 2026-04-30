IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_history'
      AND COLUMN_NAME = 'companion_credit_group_excess_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_history ADD companion_credit_group_excess_in Varchar(255);
END;