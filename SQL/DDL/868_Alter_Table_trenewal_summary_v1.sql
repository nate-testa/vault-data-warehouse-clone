IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'renewal_rate_on_line_amt'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD renewal_rate_on_line_amt [decimal](15, 2) NULL;
END;
 
 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'outstanding_in_progress_renewal_ct'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD outstanding_in_progress_renewal_ct  int NULL;
END;
 
 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'closed_with_no_offer_pending_process_renewal_ct'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD closed_with_no_offer_pending_process_renewal_ct  int NULL;
END;
 