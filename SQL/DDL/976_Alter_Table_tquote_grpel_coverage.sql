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

      IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_grpel_coverage'
      AND COLUMN_NAME = 'underlying_auto_liability_limit_amt'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage ADD underlying_auto_liability_limit_amt Varchar(255);
END;

      IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_grpel_coverage'
      AND COLUMN_NAME = 'underlying_home_liability_limit_amt'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage ADD underlying_home_liability_limit_amt Varchar(255);
END;

      IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_grpel_coverage'
      AND COLUMN_NAME = 'underlying_watercraft_liability_limit_amt'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage ADD underlying_watercraft_liability_limit_amt Varchar(255);
END;


