IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'renewal_rate_on_line_amt'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary 
    ADD renewal_rate_on_line_amt INT NULL;
END; 
 
 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'outstanding_in_progress_renewal_ct'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD outstanding_in_progress_renewal_ct  int NULL;
END;
 
 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'trenewal_summary'
      AND COLUMN_NAME = 'closed_with_no_offer_pending_process_renewal_ct'
)
BEGIN
    ALTER TABLE edw_core.trenewal_summary
    ADD closed_with_no_offer_pending_process_renewal_ct  int NULL;
END;