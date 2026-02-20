IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'bor_cancel_rw_in'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary 
    ADD bor_cancel_rw_in varchar(255) NULL;
END;  