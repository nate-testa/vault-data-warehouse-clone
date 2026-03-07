IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'mid_term_cancelled_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD mid_term_cancelled_premium_amt [decimal](15, 4) NULL;
END; 