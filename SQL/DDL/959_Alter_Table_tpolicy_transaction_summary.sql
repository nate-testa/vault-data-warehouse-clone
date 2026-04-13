IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy_transaction_summary'
      AND COLUMN_NAME = 'earned_ceded_premium_amt'
)
BEGIN
    ALTER TABLE edw_core.tpolicy_transaction_summary ADD earned_ceded_premium_amt  DECIMAL(15,2) ;
END;
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy_transaction_summary'
      AND COLUMN_NAME = 'unearned_ceded_premium_amt '
)
BEGIN
    ALTER TABLE edw_core.tpolicy_transaction_summary ADD unearned_ceded_premium_amt   DECIMAL(15,2) ;
END;
 