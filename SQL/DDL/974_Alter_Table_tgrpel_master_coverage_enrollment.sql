  IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tgrpel_master_coverage_enrollment'
      AND COLUMN_NAME = 'enrollment_end_dt'
)
BEGIN
    ALTER TABLE edw_core.tgrpel_master_coverage_enrollment ADD enrollment_end_dt DATETIME2(7) NULL;
END;