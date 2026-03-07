IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'mid_term_cancelled_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD mid_term_cancelled_premium_amt [decimal](15, 4) NULL;
END; 