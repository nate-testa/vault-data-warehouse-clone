IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE
        TABLE_SCHEMA = 'edw_commercial'
        AND TABLE_NAME = 'tcommercial_claim'
        AND COLUMN_NAME = 'salvage_recovery_expense_reserve_amt')
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim ADD salvage_recovery_expense_reserve_amt DECIMAL(15,2) NULL;
END;