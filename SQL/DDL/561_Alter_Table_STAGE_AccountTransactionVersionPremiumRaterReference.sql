IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'AccountTransactionVersionPremiumRaterReference'					
AND COLUMN_NAME = 'ExternalVersionId'					
) BEGIN ALTER TABLE edw_stage.AccountRaterRefeAccountTransactionVersionPremiumRaterReferencerence ADD ExternalVersionId nvarchar(100) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'AccountTransactionVersionPremiumRaterReference'					
AND COLUMN_NAME = 'EngineProvider'					
) BEGIN ALTER TABLE edw_stage.AccountTransactionVersionPremiumRaterReference ADD EngineProvider nvarchar(100) END