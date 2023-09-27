ALTER TABLE [edw_stage].[Account] ADD CancellationRequestedEffectiveDate datetime2; 
ALTER TABLE [edw_stage].[Account] ADD CancellationRequestedReason nvarchar(3000); 
ALTER TABLE [edw_stage].[Account] ADD CopyOfAccountNumber int; 
ALTER TABLE [edw_stage].[Account] ADD IsCancellationRequested bit ; 
ALTER TABLE [edw_stage].[Account] ADD MustCheckForms bit ; 
ALTER TABLE [edw_stage].[Account] ADD MustCheckRules bit ; 
ALTER TABLE [edw_stage].[Account] ADD OriginalEffectiveDate datetime2; 
ALTER TABLE [edw_stage].[Account] ADD Program nvarchar(2000); 
ALTER TABLE [edw_stage].[Account] ADD RenewalOfAccountId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountActivity] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountBillingPreference] ADD BillingAddressLineUnit nvarchar(500); 
ALTER TABLE [edw_stage].[AccountBillingPreference] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountChange] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountDocument] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountDocumentDelivery] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountDocumentDeliveryRecipient] ADD MailingAddressLineUnit nvarchar(500); 
ALTER TABLE [edw_stage].[AccountEligibilityQuestion] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountForm] ADD IsAttachedToPolicyChange bit ; 
ALTER TABLE [edw_stage].[AccountInsight] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountInvoice] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountInvoiceLineItem] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountObject] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountObject] ADD IsDeletedOnPolicyChange bit ; 
ALTER TABLE [edw_stage].[AccountObject] ADD TableIdentifier nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountObject] ADD UniqueId uniqueidentifier ; 
ALTER TABLE [edw_stage].[AccountObjectField] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPayment] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverride decimal; 
ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverrideByUserId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountPremium] ADD CommissionPercentOverrideRetention nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremium] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD CededPremium decimal ; 
ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ObjectId int; 
ALTER TABLE [edw_stage].[AccountPremiumCoverage] ADD ObjectUniqueId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD CustomId nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD CustomName nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD FactorMethod nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ObjectType nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD Reason nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD Retention nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountPremiumRaterReference] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD CustomName nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ObjectId int; 
ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ObjectType nvarchar(500); 
ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountPremiumTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountReport] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountReportItem] ADD DataName nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountReportItem] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountReportItem] ADD RelatedObjectId int; 

ALTER TABLE [edw_stage].[AccountTransaction] ADD DeclineNote nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountTransaction] ADD IsExternallySubmitted bit ; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD IsRenewal bit ; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD IsReversal bit ; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD IsReversed bit ; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD ReversalOfTransactionId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD StateUpdateDate datetime2 ; 
ALTER TABLE [edw_stage].[AccountTransaction] ADD TransactionReferenceCode nvarchar(100); 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremium decimal ; 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremiumDelta decimal; 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD CededPremiumDeltaProRated decimal; 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ObjectId int; 
ALTER TABLE [edw_stage].[AccountTransactionCoveragePremium] ADD ObjectUniqueId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountTransactionIssue] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD OriginalEffectiveDate datetime2; 
ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD Program nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD Description nvarchar(max); 
ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionChange] ADD IgnoreChange bit ; 
ALTER TABLE [edw_stage].[AccountTransactionVersionEligibilityQuestion] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD IsAttachedToPolicyChange bit ; 
ALTER TABLE [edw_stage].[AccountTransactionVersionInsight] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD IsDeletedOnPolicyChange bit ; 
ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD TableIdentifier nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD UniqueId uniqueidentifier ; 
ALTER TABLE [edw_stage].[AccountTransactionVersionObjectField] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverride decimal; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverrideByUserId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD CommissionPercentOverrideRetention nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD CededPremium decimal ; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ObjectId int; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumCoverage] ADD ObjectUniqueId uniqueidentifier; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD CustomId nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD CustomName nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD FactorMethod nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ObjectType nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD Reason nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD Retention nvarchar(3000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumRaterReference] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD CustomName nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ObjectId int; 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ObjectType nvarchar(500); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTransactionSummary] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BillingAccount] ADD AddressLineUnit nvarchar(500); 
ALTER TABLE [edw_stage].[BrokerageActivity] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BrokerageCommission] ADD ExpirationDate datetime2; 
ALTER TABLE [edw_stage].[BrokerageCommission] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BrokerageCompanyTeamMember] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BrokerageDocument] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BrokerOfRecordChange] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[BrokerOfRecordChangeDetail] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[DocumentIndex] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[DocumentIndexType] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[DocumentOcrResult] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[DocumentOcrResultField] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[DocumentType] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[Form] ADD IsAttachedToPolicyChange bit ; 
ALTER TABLE [edw_stage].[GraphSubscription] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[IndustryCode] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[InsuredActivity] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[LogSearchAccount] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[LogSearchInsured] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[Note] ADD IsFlagged bit ; 
ALTER TABLE [edw_stage].[Product] ADD AllowedStates nvarchar(500); 
ALTER TABLE [edw_stage].[Product] ADD AllowPolicyNumberOverride bit ; 
ALTER TABLE [edw_stage].[Product] ADD CanBindWithoutIssuance bit ; 
ALTER TABLE [edw_stage].[Product] ADD PrimaryInsuredMustBeIndividual bit ; 
ALTER TABLE [edw_stage].[ProductActivity] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[ProductDefinition] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[ProductDefinition] ADD Version nvarchar(500); 
ALTER TABLE [edw_stage].[ProductObject] ADD TableIdentifier nvarchar(2000); 
ALTER TABLE [edw_stage].[Role] ADD ExternalSourceUniqueId nvarchar(2000); 

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


ALTER TABLE [edw_stage].[Workflow] ADD Enabled bit ; 
ALTER TABLE [edw_stage].[Workflow] ADD ProductLine nvarchar(100); 
ALTER TABLE [edw_stage].[WorkflowActivity] ADD ExternalSourceUniqueId nvarchar(2000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD CompleteOnCreate bit ; 
ALTER TABLE [edw_stage].[WorkflowStep] ADD SuspenseInDays int; 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerAssignTo nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByEndorsementPremiumType nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByProgram nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByUser nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerEvent nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerSuspenseOnCreate nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerType nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkflowStepActivity] ADD ExternalSourceUniqueId nvarchar(2000); 


ALTER TABLE [edw_stage].[WorkTask] ADD AccountTransactionId uniqueidentifier; 
ALTER TABLE [edw_stage].[WorkTask] ADD ConcurrencyId nvarchar(3000); 
ALTER TABLE [edw_stage].[WorkTask] ADD FinishedById uniqueidentifier; 
ALTER TABLE [edw_stage].[WorkTask] ADD FinishedDate datetime2; 
ALTER TABLE [edw_stage].[WorkTask] ADD SuspenseUntilDate datetime2; 
ALTER TABLE [edw_stage].[WorkTaskActivity] ADD ExternalSourceUniqueId nvarchar(2000); 