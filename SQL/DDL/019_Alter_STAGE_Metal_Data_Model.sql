IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'AutoPayMethod'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD AutoPayMethod nvarchar(1000);
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'AutoPayToken'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD AutoPayToken nvarchar(1000);
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BillingAccount'
      AND COLUMN_NAME = 'IsAutoPay'
)
BEGIN
    ALTER TABLE [edw_stage].[BillingAccount] ADD IsAutoPay bit NULL;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ObjectId int;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumFactor'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumFactor] ADD ObjectUniqueId uniqueidentifier;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersionPremiumSummary'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersionPremiumSummary] ADD ObjectUniqueId uniqueidentifier;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsReviseQuote'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsReviseQuote bit NULL;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'ReviseQuoteTransactionId'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD ReviseQuoteTransactionId uniqueidentifier;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'IsCopiedFromRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ADD IsCopiedFromRenewal bit NULL;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountReport'
      AND COLUMN_NAME = 'IsCopy'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountReport] ADD IsCopy bit NULL;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'ObjectId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ObjectId int;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumFactor'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumFactor] ADD ObjectUniqueId uniqueidentifier;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPremiumSummary'
      AND COLUMN_NAME = 'ObjectUniqueId'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountPremiumSummary] ADD ObjectUniqueId uniqueidentifier;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransactionVersion'
      AND COLUMN_NAME = 'IsCopiedFromRenewal'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransactionVersion] ADD IsCopiedFromRenewal bit NULL;
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'PreviousStage'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransaction] ADD PreviousStage nvarchar(200);
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountTransaction'
      AND COLUMN_NAME = 'PreviousState'
)
BEGIN
    ALTER TABLE [edw_stage].[AccountTransaction] ADD PreviousState nvarchar(200);
END

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CopyOfAccountNumber'
)
BEGIN
    ALTER TABLE [edw_stage].[Account] ALTER COLUMN CopyOfAccountNumber nvarchar(25);
END