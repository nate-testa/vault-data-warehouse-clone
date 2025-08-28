IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'AccountPremiumCoverage'
        AND LOWER(COLUMN_NAME) = 'StatePremium')
BEGIN
    ALTER TABLE edw_stage.AccountPremiumCoverage ADD StatePremium decimal(16,4) NULL;
END