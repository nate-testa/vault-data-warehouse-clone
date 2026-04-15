IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tbilling_account_payment'
      AND COLUMN_NAME = 'payment_id'
)
BEGIN
    ALTER TABLE edw_core.tbilling_account_payment ADD payment_id int;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tbilling_account_payment'
      AND COLUMN_NAME = 'reversal_of_payment_id'
)
BEGIN
    ALTER TABLE edw_core.tbilling_account_payment ADD reversal_of_payment_id int;
END;