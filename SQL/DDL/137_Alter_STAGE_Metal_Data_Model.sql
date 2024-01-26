IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'ProductId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ProductId uniqueidentifier /*NOT NULL*/;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressCity'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressCity nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressCountry'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressCountry nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressCounty'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressCounty nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressLine1'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressLine1 nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressLine2'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressLine2 nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressLineUnit'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressLineUnit nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressState'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressState nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Insured'
      AND COLUMN_NAME = 'PriorAddressZipCode'
)
BEGIN
    ALTER TABLE [edw_stage].[Insured] ADD PriorAddressZipCode nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTaxAndFee'
      AND COLUMN_NAME = 'CoverageId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD CoverageId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTaxAndFee'
      AND COLUMN_NAME = 'RoundToNearest'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD RoundToNearest bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTaxAndFee'
      AND COLUMN_NAME = 'TaxFullyEarnedFee'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD TaxFullyEarnedFee bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumTaxAndFee'
      AND COLUMN_NAME = 'TaxRate'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumTaxAndFee] ADD TaxRate decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReport'
      AND COLUMN_NAME = 'IsReportFromCache'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountReport] ADD IsReportFromCache bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReport'
      AND COLUMN_NAME = 'RequestRawExtension'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountReport] ADD RequestRawExtension nvarchar(10);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReport'
      AND COLUMN_NAME = 'ResponseRawExtension'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountReport] ADD ResponseRawExtension nvarchar(10);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'BrokerageMustHaveEffectiveLicenseToBind'
)
BEGIN
    ALTER TABLE [edw_stage].[Product] ADD BrokerageMustHaveEffectiveLicenseToBind bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'CanChangeRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[Product] ADD CanChangeRiskState bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'ProductOrder'
)
BEGIN
    ALTER TABLE [edw_stage].[Product] ADD ProductOrder int /*NOT NULL*/;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Product'
      AND COLUMN_NAME = 'AllowCommissionChangeOnEndorsement'
)
BEGIN
    ALTER TABLE [edw_stage].[Product] ADD AllowCommissionChangeOnEndorsement bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountRequirement'
      AND COLUMN_NAME = 'DisplayExternal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountRequirement] ADD DisplayExternal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS

    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'CancellationSubReason'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransaction] ADD CancellationSubReason nvarchar(2000);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'WillReApplyDuringReinstatement'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransaction] ADD WillReApplyDuringReinstatement bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionRequirement'
      AND COLUMN_NAME = 'DisplayExternal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionRequirement] ADD DisplayExternal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionTaxAndFee'
      AND COLUMN_NAME = 'CoverageId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD CoverageId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionTaxAndFee'
      AND COLUMN_NAME = 'RoundToNearest'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD RoundToNearest bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionTaxAndFee'
      AND COLUMN_NAME = 'TaxFullyEarnedFee'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD TaxFullyEarnedFee bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionTaxAndFee'
      AND COLUMN_NAME = 'TaxRate'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionTaxAndFee] ADD TaxRate decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'InitialPolicyNumber'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD InitialPolicyNumber nvarchar(25);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'IsCopiedFromNonRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD IsCopiedFromNonRenewal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'CanChangeRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD CanChangeRiskState bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'StampDocumentId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD StampDocumentId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'PolicyChangeRequest'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD PolicyChangeRequest nvarchar(3800);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionForm'
      AND COLUMN_NAME = 'StampRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD StampRiskState nvarchar(50);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionForm'
      AND COLUMN_NAME = 'ShowOnFormList'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionForm] ADD ShowOnFormList bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'IsAddedOnPolicyChange'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD IsAddedOnPolicyChange bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObject'
      AND COLUMN_NAME = 'IsAddedOnRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionObject] ADD IsAddedOnRenewal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'MustManuallyComplete'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkflowStep] ADD MustManuallyComplete bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerByExcludeRiskStates'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByExcludeRiskStates nvarchar(3000);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'TriggerByRiskStates'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkflowStep] ADD TriggerByRiskStates nvarchar(3000);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkflowStep'
      AND COLUMN_NAME = 'IsFollowUpTask'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkflowStep] ADD IsFollowUpTask bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionObjectField'
      AND COLUMN_NAME = 'ValueBlob'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionObjectField] ADD ValueBlob nvarchar(max);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'ExcludedDriverPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD ExcludedDriverPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremium'
      AND COLUMN_NAME = 'IncidentAdjustedPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremium] ADD IncidentAdjustedPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'MustManuallyComplete'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkTask] ADD MustManuallyComplete bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'FollowUpDate'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkTask] ADD FollowUpDate datetime2;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'WorkTask'
      AND COLUMN_NAME = 'IsFollowUpTask'
)
BEGIN
    ALTER TABLE [edw_stage].[WorkTask] ADD IsFollowUpTask bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'ProductId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ProductId uniqueidentifier /*NOT NULL*/;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumRaterReference'
      AND COLUMN_NAME = 'ReferenceType'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumRaterReference] ADD ReferenceType nvarchar(200);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumRaterReference'
      AND COLUMN_NAME = 'Version'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumRaterReference] ADD Version nvarchar(20);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTaxAndFee'
      AND COLUMN_NAME = 'CoverageId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD CoverageId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTaxAndFee'
      AND COLUMN_NAME = 'RoundToNearest'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD RoundToNearest bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTaxAndFee'
      AND COLUMN_NAME = 'TaxFullyEarnedFee'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD TaxFullyEarnedFee bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumTaxAndFee'
      AND COLUMN_NAME = 'TaxRate'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumTaxAndFee] ADD TaxRate decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'BillToMortgageeId'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD BillToMortgageeId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'CustomerNotificationDate'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD CustomerNotificationDate datetime2;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'IsNotificationNeeded'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD IsNotificationNeeded bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'InitialPolicyNumber'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD InitialPolicyNumber nvarchar(25);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsCopiedFromNonRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsCopiedFromNonRenewal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CanChangeRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD CanChangeRiskState bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'RenewalReviewStartDate'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD RenewalReviewStartDate datetime2;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsRewritten'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsRewritten bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'RewrittenAccountId'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD RewrittenAccountId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'RewrittenFromAccountId'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD RewrittenFromAccountId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'RewrittenIndex'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD RewrittenIndex int /*NOT NULL*/;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsPendingCancel'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsPendingCancel bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'AdjustedInflationPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD AdjustedInflationPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'PriorTotalPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD PriorTotalPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'ProductSchemaVersionId'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD ProductSchemaVersionId nvarchar(500);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsRenewalReviewCreated'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsRenewalReviewCreated bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'PolicyChangeRequest'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD PolicyChangeRequest nvarchar(3800);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'PriorPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD PriorPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'PreBindComplete'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD PreBindComplete bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'BrokerOfRecordChangeApplied'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD BrokerOfRecordChangeApplied bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'BrokerOfRecordChangeAppliedToAccountId'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD BrokerOfRecordChangeAppliedToAccountId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'

      AND TABLE_NAME = 'AccountActivity'
      AND COLUMN_NAME = 'IsHidden'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountActivity] ADD IsHidden bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountActivity'
      AND COLUMN_NAME = 'NewValueBlob'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountActivity] ADD NewValueBlob nvarchar(max);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountActivity'
      AND COLUMN_NAME = 'ObjectIdentifier'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountActivity] ADD ObjectIdentifier nvarchar(3000);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountActivity'
      AND COLUMN_NAME = 'OldValueBlob'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountActivity] ADD OldValueBlob nvarchar(max);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Document'
      AND COLUMN_NAME = 'Source'
)
BEGIN
    ALTER TABLE [edw_stage].[Document] ADD Source nvarchar(200);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Document'
      AND COLUMN_NAME = 'DocumentFolderId'
)
BEGIN
    ALTER TABLE [edw_stage].[Document] ADD DocumentFolderId uniqueidentifier;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountForm'
      AND COLUMN_NAME = 'StampRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountForm] ADD StampRiskState nvarchar(50);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountForm'
      AND COLUMN_NAME = 'ShowOnFormList'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountForm] ADD ShowOnFormList bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'IsAddedOnPolicyChange'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountObject] ADD IsAddedOnPolicyChange bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObject'
      AND COLUMN_NAME = 'IsAddedOnRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountObject] ADD IsAddedOnRenewal bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObjectField'
      AND COLUMN_NAME = 'Required'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountObjectField] ADD Required nvarchar(200);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountObjectField'
      AND COLUMN_NAME = 'ValueBlob'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountObjectField] ADD ValueBlob nvarchar(max);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Form'
      AND COLUMN_NAME = 'StampRiskState'
)
BEGIN
    ALTER TABLE [edw_stage].[Form] ADD StampRiskState nvarchar(50);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Form'
      AND COLUMN_NAME = 'ShowOnFormList'
)
BEGIN
    ALTER TABLE [edw_stage].[Form] ADD ShowOnFormList bit;
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'ExcludedDriverPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremium] ADD ExcludedDriverPremium decimal(16,4);
END;

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremium'
      AND COLUMN_NAME = 'IncidentAdjustedPremium'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremium] ADD IncidentAdjustedPremium decimal(16,4);
END;

