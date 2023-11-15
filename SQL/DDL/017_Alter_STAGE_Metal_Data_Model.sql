-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CancellationRequestedEffectiveDate'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD CancellationRequestedEffectiveDate datetime2 ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CancellationRequestedReason'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD CancellationRequestedReason nvarchar(3000) ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CopyOfAccountNumber'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD CopyOfAccountNumber int ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsCancellationRequested'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD IsCancellationRequested bit  ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'MustCheckForms'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD MustCheckForms bit  ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'MustCheckRules'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD MustCheckRules bit  ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'OriginalEffectiveDate'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD OriginalEffectiveDate datetime2 ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'Program'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD Program nvarchar(2000) ;
END

-- Account table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'RenewalOfAccountId'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ADD RenewalOfAccountId uniqueidentifier ;
END

-- AccountActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountBillingPreference table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountBillingPreference'
      AND COLUMN_NAME = 'BillingAddressLineUnit'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountBillingPreference] ADD BillingAddressLineUnit nvarchar(500) ;
END

-- AccountBillingPreference table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountBillingPreference'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountBillingPreference] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountChange table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountChange'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountChange] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountDocument table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountDocument'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountDocument] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountDocumentDelivery table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountDocumentDelivery'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountDocumentDelivery] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountDocumentDeliveryRecipient table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountDocumentDeliveryRecipient'
      AND COLUMN_NAME = 'MailingAddressLineUnit'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountDocumentDeliveryRecipient] ADD MailingAddressLineUnit nvarchar(500) ;
END

-- AccountEligibilityQuestion table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountEligibilityQuestion'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountEligibilityQuestion] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountForm table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountForm'
      AND COLUMN_NAME = 'IsAttachedToPolicyChange'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountForm] ADD IsAttachedToPolicyChange bit  ;
END

-- AccountInsight table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountInsight'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountInsight] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountInvoice table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountInvoice'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountInvoice] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountInvoiceLineItem table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountInvoiceLineItem'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountInvoiceLineItem] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountObject] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'IsDeletedOnPolicyChange'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountObject] ADD IsDeletedOnPolicyChange bit  ;
END

-- AccountObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'TableIdentifier'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountObject] ADD TableIdentifier nvarchar(2000) ;
END

-- AccountObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'UniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountObject] ADD UniqueId uniqueidentifier  ;
END

-- AccountObjectField table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObjectField'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountObjectField] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPayment table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPayment'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPayment] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'CommissionPercentOverride'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverride decimal ;
END

-- AccountPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'CommissionPercentOverrideByUserId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverrideByUserId uniqueidentifier ;
END

-- AccountPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'CommissionPercentOverrideRetention'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverrideRetention nvarchar(2000) ;
END

-- AccountPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremium] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumCoverage'
      AND COLUMN_NAME = 'CededPremium'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD CededPremium decimal  ;
END

-- AccountPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumCoverage'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumCoverage'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ObjectId int ;
END

-- AccountPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumCoverage'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ObjectUniqueId uniqueidentifier ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'CustomId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD CustomId nvarchar(500) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'CustomName'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD CustomName nvarchar(500) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'FactorMethod'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD FactorMethod nvarchar(500) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'ObjectType'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ObjectType nvarchar(500) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'Reason'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD Reason nvarchar(3000) ;
END

-- AccountPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'Retention'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD Retention nvarchar(3000) ;
END

-- AccountPremiumRaterReference table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumRaterReference'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumRaterReference] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumSummary'
      AND COLUMN_NAME = 'CustomName'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD CustomName nvarchar(500) ;
END

-- AccountPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumSummary'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumSummary'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ObjectId int ;
END

-- AccountPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumSummary'
      AND COLUMN_NAME = 'ObjectType'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ObjectType nvarchar(500) ;
END

-- AccountPremiumTaxAndFee table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTaxAndFee'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountPremiumTransactionSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTransactionSummary'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountPremiumTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountReport table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReport'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountReport] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountReportItem table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReportItem'
      AND COLUMN_NAME = 'DataName'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountReportItem] ADD DataName nvarchar(3000) ;
END

-- AccountReportItem table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReportItem'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountReportItem] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountReportItem table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReportItem'
      AND COLUMN_NAME = 'RelatedObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountReportItem] ADD RelatedObjectId int ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'DeclineNote'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD DeclineNote nvarchar(3000) ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'IsExternallySubmitted'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD IsExternallySubmitted bit  ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'IsRenewal'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD IsRenewal bit  ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'IsReversal'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD IsReversal bit  ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'IsReversed'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD IsReversed bit  ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'ReversalOfTransactionId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD ReversalOfTransactionId uniqueidentifier ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'StateUpdateDate'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD StateUpdateDate datetime2  ;
END

-- AccountTransaction table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'TransactionReferenceCode'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransaction] ADD TransactionReferenceCode nvarchar(100) ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'CededPremium'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremium decimal  ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'CededPremiumDelta'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremiumDelta decimal ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'CededPremiumDeltaProRated'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremiumDeltaProRated decimal ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ObjectId int ;
END

-- AccountTransactionCoveragePremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionCoveragePremium'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ObjectUniqueId uniqueidentifier ;
END

-- AccountTransactionIssue table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionIssue'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionIssue] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionSummary'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionTaxAndFee table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionTaxAndFee'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersion table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersion table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'OriginalEffectiveDate'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD OriginalEffectiveDate datetime2 ;
END

-- AccountTransactionVersion table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'Program'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD Program nvarchar(2000) ;
END

-- AccountTransactionVersionChange table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionChange'
      AND COLUMN_NAME = 'Description'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD Description nvarchar(max) ;
END

-- AccountTransactionVersionChange table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionChange'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionChange table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionChange'
      AND COLUMN_NAME = 'IgnoreChange'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD IgnoreChange bit  ;
END

-- AccountTransactionVersionEligibilityQuestion table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionEligibilityQuestion'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionEligibilityQuestion] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionForm table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionForm'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionForm table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionForm'
      AND COLUMN_NAME = 'IsAttachedToPolicyChange'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD IsAttachedToPolicyChange bit  ;
END

-- AccountTransactionVersionInsight table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionInsight'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionInsight] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'IsDeletedOnPolicyChange'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD IsDeletedOnPolicyChange bit  ;
END

-- AccountTransactionVersionObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'TableIdentifier'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD TableIdentifier nvarchar(2000) ;
END

-- AccountTransactionVersionObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'UniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD UniqueId uniqueidentifier  ;
END

-- AccountTransactionVersionObjectField table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObjectField'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionObjectField] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'CommissionPercentOverride'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverride decimal ;
END

-- AccountTransactionVersionPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'CommissionPercentOverrideByUserId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverrideByUserId uniqueidentifier ;
END

-- AccountTransactionVersionPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'CommissionPercentOverrideRetention'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverrideRetention nvarchar(2000) ;
END

-- AccountTransactionVersionPremium table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumCoverage'
      AND COLUMN_NAME = 'CededPremium'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD CededPremium decimal  ;
END

-- AccountTransactionVersionPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumCoverage'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumCoverage'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ObjectId int ;
END

-- AccountTransactionVersionPremiumCoverage table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumCoverage'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ObjectUniqueId uniqueidentifier ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'CustomId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD CustomId nvarchar(500) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'CustomName'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD CustomName nvarchar(500) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'FactorMethod'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD FactorMethod nvarchar(500) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'ObjectType'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ObjectType nvarchar(500) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'Reason'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD Reason nvarchar(3000) ;
END

-- AccountTransactionVersionPremiumFactor table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'Retention'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD Retention nvarchar(3000) ;
END

-- AccountTransactionVersionPremiumRaterReference table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumRaterReference'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumRaterReference] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumSummary'
      AND COLUMN_NAME = 'CustomName'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD CustomName nvarchar(500) ;
END

-- AccountTransactionVersionPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumSummary'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumSummary'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ObjectId int ;
END

-- AccountTransactionVersionPremiumSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumSummary'
      AND COLUMN_NAME = 'ObjectType'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ObjectType nvarchar(500) ;
END

-- AccountTransactionVersionPremiumTaxAndFee table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTaxAndFee'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- AccountTransactionVersionPremiumTransactionSummary table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTransactionSummary'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BillingAccount table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'AddressLineUnit'
)
BEGIN
	ALTER TABLE [edw_stage].[BillingAccount] ADD AddressLineUnit nvarchar(500) ;
END

-- BrokerageActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerageActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BrokerageCommission table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageCommission'
      AND COLUMN_NAME = 'ExpirationDate'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerageCommission] ADD ExpirationDate datetime2 ;
END

-- BrokerageCommission table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageCommission'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerageCommission] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BrokerageCompanyTeamMember table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageCompanyTeamMember'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerageCompanyTeamMember] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BrokerageDocument table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageDocument'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerageDocument] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BrokerOfRecordChange table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerOfRecordChange'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerOfRecordChange] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- BrokerOfRecordChangeDetail table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerOfRecordChangeDetail'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[BrokerOfRecordChangeDetail] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- DocumentIndex table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'DocumentIndex'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[DocumentIndex] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- DocumentIndexType table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'DocumentIndexType'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[DocumentIndexType] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- DocumentOcrResult table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'DocumentOcrResult'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[DocumentOcrResult] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- DocumentOcrResultField table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'DocumentOcrResultField'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[DocumentOcrResultField] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- DocumentType table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'DocumentType'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[DocumentType] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- Form table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Form'
      AND COLUMN_NAME = 'IsAttachedToPolicyChange'
)
BEGIN
	ALTER TABLE [edw_stage].[Form] ADD IsAttachedToPolicyChange bit  ;
END

-- GraphSubscription table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'GraphSubscription'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[GraphSubscription] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- IndustryCode table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'IndustryCode'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[IndustryCode] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- InsuredActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'InsuredActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[InsuredActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- LogSearchAccount table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'LogSearchAccount'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[LogSearchAccount] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- LogSearchInsured table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'LogSearchInsured'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[LogSearchInsured] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- Note table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Note'
      AND COLUMN_NAME = 'IsFlagged'
)
BEGIN
	ALTER TABLE [edw_stage].[Note] ADD IsFlagged bit  ;
END

-- Product table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'AllowedStates'
)
BEGIN
	ALTER TABLE [edw_stage].[Product] ADD AllowedStates nvarchar(500) ;
END

-- Product table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'AllowPolicyNumberOverride'
)
BEGIN
	ALTER TABLE [edw_stage].[Product] ADD AllowPolicyNumberOverride bit  ;
END

-- Product table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'CanBindWithoutIssuance'
)
BEGIN
	ALTER TABLE [edw_stage].[Product] ADD CanBindWithoutIssuance bit  ;
END

-- Product table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'PrimaryInsuredMustBeIndividual'
)
BEGIN
	ALTER TABLE [edw_stage].[Product] ADD PrimaryInsuredMustBeIndividual bit  ;
END

-- ProductActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'ProductActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[ProductActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- ProductDefinition table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'ProductDefinition'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[ProductDefinition] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- ProductDefinition table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'ProductDefinition'
      AND COLUMN_NAME = 'Version'
)
BEGIN
	ALTER TABLE [edw_stage].[ProductDefinition] ADD Version nvarchar(500) ;
END

-- ProductObject table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'ProductObject'
      AND COLUMN_NAME = 'TableIdentifier'
)
BEGIN
	ALTER TABLE [edw_stage].[ProductObject] ADD TableIdentifier nvarchar(2000) ;
END

-- Role table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Role'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[Role] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

IF NOT EXISTS (SELECT 1 
               FROM sys.tables 
               WHERE name = 'WebhookRequestLog' 
               AND schema_id = SCHEMA_ID('edw_stage'))
BEGIN
    CREATE TABLE [edw_stage].[WebhookRequestLog]
    (
        [Id] [uniqueidentifier] NOT NULL,
        [RequestLog] [nvarchar](max) NULL,
        [Type] [nvarchar](200) NULL,
        [Status] [nvarchar](200) NULL,
        [ErrorMessage] [nvarchar](2000) NULL,
        [ExternalSourceId] [nvarchar](2000) NULL,
        [CreatedDate] [datetime2](7) NOT NULL,
        [UpdatedDate] [datetime2](7) NOT NULL,
        CONSTRAINT PK_WebhookRequestLog PRIMARY KEY(id)
    );
END;

-- Workflow table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Workflow'
      AND COLUMN_NAME = 'Enabled'
)
BEGIN
	ALTER TABLE [edw_stage].[Workflow] ADD Enabled bit  ;
END

-- Workflow table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Workflow'
      AND COLUMN_NAME = 'ProductLine'
)
BEGIN
	ALTER TABLE [edw_stage].[Workflow] ADD ProductLine nvarchar(100) ;
END

-- WorkflowActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'CompleteOnCreate'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD CompleteOnCreate bit  ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'SuspenseInDays'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD SuspenseInDays int ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerAssignTo'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerAssignTo nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerByEndorsementPremiumType'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByEndorsementPremiumType nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerByProgram'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByProgram nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerByUser'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByUser nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerEvent'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerEvent nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerSuspenseOnCreate'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerSuspenseOnCreate nvarchar(3000) ;
END

-- WorkflowStep table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerType'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerType nvarchar(3000) ;
END

-- WorkflowStepActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStepActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkflowStepActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

-- WorkTask table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'AccountTransactionId'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTask] ADD AccountTransactionId uniqueidentifier ;
END

-- WorkTask table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'ConcurrencyId'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTask] ADD ConcurrencyId nvarchar(3000) ;
END

-- WorkTask table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'FinishedById'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTask] ADD FinishedById uniqueidentifier ;
END

-- WorkTask table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'FinishedDate'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTask] ADD FinishedDate datetime2 ;
END

-- WorkTask table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'SuspenseUntilDate'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTask] ADD SuspenseUntilDate datetime2 ;
END

-- WorkTaskActivity table column additions
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTaskActivity'
      AND COLUMN_NAME = 'ExternalSourceUniqueId'
)
BEGIN
	ALTER TABLE [edw_stage].[WorkTaskActivity] ADD ExternalSourceUniqueId nvarchar(2000) ;
END

