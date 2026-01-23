IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'in_progress_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD in_progress_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'closed_with_no_offer_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD closed_with_no_offer_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'accepted_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD accepted_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'not_accepted_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD not_accepted_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'outstanding_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD outstanding_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'need_attention_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD need_attention_premium_amt DECIMAL(15, 2) NULL;
END;

