IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'AccountRaterReference'					
AND COLUMN_NAME = 'ExternalVersionId'					
) BEGIN ALTER TABLE edw_stage.AccountRaterReference ADD ExternalVersionId nvarchar(100) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'AccountRaterReference'					
AND COLUMN_NAME = 'EngineProvider'					
) BEGIN ALTER TABLE edw_stage.AccountRaterReference ADD EngineProvider nvarchar(100) END