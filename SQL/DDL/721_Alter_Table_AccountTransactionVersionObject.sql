iF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_stage'
AND TABLE_NAME = 'AccountTransactionVersionObject'
AND LOWER(COLUMN_NAME) = 'IsDeletedOnRenewal'
) BEGIN ALTER TABLE edw_stage.AccountTransactionVersionObject ADD IsDeletedOnRenewal bit NULL END ;