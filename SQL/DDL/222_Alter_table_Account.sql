IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'CopiedToAccountId' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD CopiedToAccountId uniqueidentifier;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'CopiedToAccountNumber' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD CopiedToAccountNumber nvarchar(25);
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'IsIntegrationDisable' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD IsIntegrationDisable bit CONSTRAINT DF_IsIntegrationDisable DEFAULT 0;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'RenewalCapFactor' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD RenewalCapFactor decimal(16, 4);
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'RenewalCapPercent' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD RenewalCapPercent decimal(16, 4);
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'IsRenewalRequoted' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD IsRenewalRequoted bit CONSTRAINT DF_IsRenewalRequoted DEFAULT 0;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'IsExcessCoverage' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD IsExcessCoverage bit CONSTRAINT DF_IsExcessCoverage DEFAULT 0;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'IsOfferedAtLeastOne' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD IsOfferedAtLeastOne bit CONSTRAINT DF_IsOfferedAtLeastOne DEFAULT 0;
END

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE Name = N'PremiumChangedSincePriorFirstTransactionPercentage' AND Object_ID = Object_ID(N'edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account
    ADD PremiumChangedSincePriorFirstTransactionPercentage decimal(16, 4);
END