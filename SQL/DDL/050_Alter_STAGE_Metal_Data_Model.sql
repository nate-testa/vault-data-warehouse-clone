
ALTER TABLE [edw_stage].[Account] ADD NonRenewalStateNote nvarchar(3000);
ALTER TABLE [edw_stage].[Broker] ADD Disabled bit ;
ALTER TABLE [edw_stage].[User] ADD Disable bit;
ALTER TABLE [edw_stage].[Account] ADD NonRenewalStateSubNote nvarchar(3000);
ALTER TABLE [edw_stage].[AccountTransactionVersion] ALTER COLUMN [MinimumEarnedPremiumPercent] decimal(16,4) NOT NULL;
ALTER TABLE [edw_stage].[AccountTransaction] ALTER COLUMN [MinimumEarnedPremiumPercent] decimal(16,4) NOT NULL;
ALTER TABLE [edw_stage].[Account] ALTER COLUMN [MinimumEarnedPremiumPercent] decimal(16,4) NOT NULL;
ALTER TABLE [edw_stage].[Account] ADD [IsConditionalRenewal] bit NOT NULL DEFAULT CAST(0 AS bit);
ALTER TABLE [edw_stage].[ProductObjectField] ADD [Required] nvarchar(200) NULL;
ALTER TABLE [edw_stage].[AccountTransactionVersionObjectField] ADD [Required] nvarchar(200) NULL;
ALTER TABLE [edw_stage].[BillingAccount] ADD [EmailUpdated] bit DEFAULT CAST(0 AS bit);

CREATE TABLE [edw_stage].[AccountTransactionRequirement]
(
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [AccountTransactionId] UNIQUEIDENTIFIER NOT NULL,
    [RequirementId] UNIQUEIDENTIFIER NOT NULL,
    [Message] NVARCHAR(4000) NULL,
    [Prevent] NVARCHAR(400) NULL,
    [ExternalSourceId] NVARCHAR(4000) NULL,
    [CreatedDate] DATETIME2 NOT NULL,
    [UpdatedDate] DATETIME2 NOT NULL
);

CREATE TABLE [edw_stage].[InsuredDocument]
(
    [Id] INT NOT NULL,
    [DocumentId] UNIQUEIDENTIFIER NOT NULL,
    [InsuredId] UNIQUEIDENTIFIER NOT NULL,
    [ExternalSourceId] NVARCHAR(4000) NULL,
    [ExternalSourceUniqueId] NVARCHAR(4000) NULL,
    [CreatedDate] DATETIME2 NOT NULL,
    [UpdatedDate] DATETIME2 NULL
);