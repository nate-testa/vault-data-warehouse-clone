IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'InsuredMarketingPreference'
AND COLUMN_NAME = 'Product'
)
BEGIN
    ALTER TABLE edw_stage.InsuredMarketingPreference ADD Product nvarchar(max) NULL
END ;

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'InsuredMarketingPreference'
AND COLUMN_NAME = 'PrimaryAccountId'
)
BEGIN
    ALTER TABLE edw_stage.InsuredMarketingPreference ADD PrimaryAccountId uniqueidentifier NULL
END ;