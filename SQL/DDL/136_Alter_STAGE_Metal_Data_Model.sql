-- Create [edw_stage].[AccountRelatedAddress] table
IF OBJECT_ID('[edw_stage].[AccountRelatedAddress]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[AccountRelatedAddress] (
        [Id] INT NOT NULL,
        [AccountId] UNIQUEIDENTIFIER NOT NULL,
        [ObjectType] NVARCHAR(400) NULL,
        [ObjectUniqueId] UNIQUEIDENTIFIER NOT NULL,
        [FieldGroup] NVARCHAR(4000) NULL,
        [FullAddress] NVARCHAR(4000) NULL,
        [IsMailing] BIT NOT NULL,
        [IsRisk] BIT NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[AccountRelatedProductCount] table
IF OBJECT_ID('[edw_stage].[AccountRelatedProductCount]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[AccountRelatedProductCount] (
        [Id] INT NOT NULL,
        [AccountId] UNIQUEIDENTIFIER NOT NULL,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [Total] INT NOT NULL,
        [IsBound] BIT NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[AccountReportDocument] table
IF OBJECT_ID('[edw_stage].[AccountReportDocument]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[AccountReportDocument] (
        [Id] INT NOT NULL,
        [ReportId] INT NOT NULL,
        [DocumentId] UNIQUEIDENTIFIER NOT NULL,
        [Description] NVARCHAR(4000) NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[DocumentFolder] table
IF OBJECT_ID('[edw_stage].[DocumentFolder]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[DocumentFolder] (
        [Id] UNIQUEIDENTIFIER NOT NULL,
        [Name] NVARCHAR(400) NULL,
        [DocumentFolderType] NVARCHAR(400) NULL,
        [ParentFolderId] UNIQUEIDENTIFIER NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NOT NULL
    );
END;

-- Create [edw_stage].[AccountRaterReference] table
IF OBJECT_ID('[edw_stage].[AccountRaterReference]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[AccountRaterReference] (
        [Id] INT NOT NULL,
        [AccountId] UNIQUEIDENTIFIER NOT NULL,
        [BlobIdentifier] NVARCHAR(600) NULL,
        [Extension] NVARCHAR(40) NULL,
        [ReferenceUrl] NVARCHAR(4000) NULL,
        [ProductInternalName] NVARCHAR(600) NULL,
        [ReferenceType] NVARCHAR(400) NULL,
        [Version] NVARCHAR(40) NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[BillingAccountLog] table
IF OBJECT_ID('[edw_stage].[BillingAccountLog]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[BillingAccountLog] (
        [Id] INT NOT NULL,
        [BillingAccountId] UNIQUEIDENTIFIER NULL,
        [AccountInvoiceId] INT NULL,
        [AccountVersionId] INT NULL,
        [BrokerageId] UNIQUEIDENTIFIER NULL,
        [InsuredId] UNIQUEIDENTIFIER NULL,
        [Event] NVARCHAR(1000) NULL,
        [Index] INT NOT NULL,
        [Error] NVARCHAR(MAX) NULL,
        [Request] NVARCHAR(MAX) NULL,
        [Proceeded] BIT NOT NULL,
        [ProceededSuccess] BIT NOT NULL,
        [ProcessByName] NVARCHAR(1000) NULL,
        [ProcessDate] DATETIME2 NOT NULL,
        [InsuredUpdate] BIT NOT NULL,
        [MovePolicy] BIT NOT NULL,
        [UpdateExistingBillingAccount] BIT NOT NULL,
        [MoveNewBillingAccount] BIT NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[CommissionTier] table
IF OBJECT_ID('[edw_stage].[CommissionTier]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[CommissionTier] (
        [Id] UNIQUEIDENTIFIER NOT NULL,
        [Name] NVARCHAR(400) NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NOT NULL
    );
END;

-- Create [edw_stage].[CommissionTierBrokerage] table
IF OBJECT_ID('[edw_stage].[CommissionTierBrokerage]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[CommissionTierBrokerage] (
        [Id] INT NOT NULL,
        [CommissionTierId] UNIQUEIDENTIFIER NOT NULL,
        [BrokerageId] UNIQUEIDENTIFIER NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL,
        [EffectiveDate] DATETIME2 NOT NULL DEFAULT('0001-01-01T00:00:00.0000000'),
        [ExpirationDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[CommissionTierPercentage] table
IF OBJECT_ID('[edw_stage].[CommissionTierPercentage]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[CommissionTierPercentage] (
        [Id] INT NOT NULL,
        [CommissionTierId] UNIQUEIDENTIFIER NOT NULL,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [CoverageId] UNIQUEIDENTIFIER NULL,
        [State] NVARCHAR(100) NULL,
        [ProgramType] NVARCHAR(400) NULL,
        [BusinessType] NVARCHAR(400) NULL,
        [CommissionPercent] DECIMAL(16, 4) NOT NULL,
        [EffectiveDate] DATETIME2 NOT NULL,
        [ExpirationDate] DATETIME2 NULL,
        [IsExpired] BIT NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NULL
    );
END;

-- Create [edw_stage].[CommissionGlobalExclusion] table
IF OBJECT_ID('[edw_stage].[CommissionGlobalExclusion]') IS NULL
BEGIN
    CREATE TABLE [edw_stage].[CommissionGlobalExclusion] (
        [Id] UNIQUEIDENTIFIER NOT NULL,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [KeepAtRenewalForStatesIfTerminated] NVARCHAR(MAX) NULL,
        [MustHaveCompanionProducts] BIT NOT NULL,
        [CompanionProducts] NVARCHAR(MAX) NULL,
        [CommissionPercentIfFail] DECIMAL(16, 4) NOT NULL,
        [ExternalSourceId] NVARCHAR(4000) NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [UpdatedDate] DATETIME2 NOT NULL
    );
END;