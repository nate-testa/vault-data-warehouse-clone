IF NOT EXISTS
(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'InsuredMarketingPreference')
BEGIN
CREATE TABLE edw_stage.InsuredMarketingPreference(
Id uniqueidentifier NOT NULL,
InsuredId uniqueidentifier NOT NULL,
OptOut bit NOT NULL,
Description nvarchar(500) NOT NULL,
InternalCode nvarchar(200) NOT NULL,
MarketingDocumentData nvarchar(max) NULL,
ExternalSourceId nvarchar(2000) NULL,
CreatedDate datetime2(7) NOT NULL,
UpdatedDate datetime2(7) NOT NULL
)
END ;