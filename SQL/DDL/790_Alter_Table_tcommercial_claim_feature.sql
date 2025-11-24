IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE
        TABLE_SCHEMA = 'edw_commercial'
        AND TABLE_NAME = 'tcommercial_claim_feature'
        AND COLUMN_NAME = 'subrogation_expense_recovery_amt')
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim_feature ADD subrogation_expense_recovery_amt DECIMAL(15,2) NULL;
END;