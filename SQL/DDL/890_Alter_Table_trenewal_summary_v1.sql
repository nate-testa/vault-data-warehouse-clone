IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'bor_cancel_rw_in'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1 
    ADD bor_cancel_rw_in varchar(255) NULL;
END;  