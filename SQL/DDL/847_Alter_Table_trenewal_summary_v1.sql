IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'in_progress_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD in_progress_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'closed_with_no_offer_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD closed_with_no_offer_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'accepted_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD accepted_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'not_accepted_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD not_accepted_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'outstanding_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD outstanding_premium_amt DECIMAL(15, 2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'need_attention_premium_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD need_attention_premium_amt DECIMAL(15, 2) NULL;
END;

