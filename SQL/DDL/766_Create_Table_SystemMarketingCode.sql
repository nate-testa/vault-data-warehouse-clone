IF NOT EXISTS
(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'SystemMarketingCode')
BEGIN
CREATE TABLE edw_stage.SystemMarketingCode(
Id uniqueidentifier NOT NULL,
Description nvarchar(500) NOT NULL,
InternalCode nvarchar(200) NOT NULL,
AppliedToExistingInsureds bit NOT NULL,
ExternalSourceId nvarchar(2000) NULL,
CreatedDate datetime2(7) NOT NULL,
UpdatedDate datetime2(7) NOT NULL
)
END ;