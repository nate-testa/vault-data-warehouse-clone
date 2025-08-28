IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'AccountTransactionCoveragePremium'
        AND LOWER(COLUMN_NAME) = 'StatePremium')
BEGIN
    ALTER TABLE edw_stage.AccountTransactionCoveragePremium ADD StatePremium decimal(16,4) NULL;
END

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'AccountTransactionCoveragePremium'
        AND LOWER(COLUMN_NAME) = 'StatePremiumDelta')
BEGIN
    ALTER TABLE edw_stage.AccountTransactionCoveragePremium ADD StatePremiumDelta decimal(16,4) NULL;
END

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'AccountTransactionCoveragePremium'
        AND LOWER(COLUMN_NAME) = 'StatePremiumDeltaProRated')
BEGIN
    ALTER TABLE edw_stage.AccountTransactionCoveragePremium ADD StatePremiumDeltaProRated decimal(16,4) NULL;
END
