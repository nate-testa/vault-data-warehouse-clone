IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'StatusSentToBroker' AND object_id = OBJECT_ID('edw_stage.AccountTransactionStatusHistory'))
BEGIN
    ALTER TABLE edw_stage.AccountTransactionStatusHistory ADD StatusSentToBroker bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'InProgressStartedDate' AND object_id = OBJECT_ID('edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account ADD InProgressStartedDate datetime2;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'InProgressStartedUserId' AND object_id = OBJECT_ID('edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account ADD InProgressStartedUserId uniqueidentifier;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'IsInternalCreated' AND object_id = OBJECT_ID('edw_stage.Account'))
BEGIN
    ALTER TABLE edw_stage.Account ADD IsInternalCreated bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'InternalSourceUrl' AND object_id = OBJECT_ID('edw_stage.WorkTask'))
BEGIN
    ALTER TABLE edw_stage.WorkTask ADD InternalSourceUrl nvarchar(3000);
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'TriggerServiceName' AND object_id = OBJECT_ID('edw_stage.WorkflowStep'))
BEGIN
    ALTER TABLE edw_stage.WorkflowStep ADD TriggerServiceName nvarchar(3000);
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'CheckExcessCoverage' AND object_id = OBJECT_ID('edw_stage.ProductPolicyNumberRange'))
BEGIN
    ALTER TABLE edw_stage.ProductPolicyNumberRange ADD CheckExcessCoverage bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'IsExcessCoverage' AND object_id = OBJECT_ID('edw_stage.ProductPolicyNumberRange'))
BEGIN
    ALTER TABLE edw_stage.ProductPolicyNumberRange ADD IsExcessCoverage bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'IsExternalShared' AND object_id = OBJECT_ID('edw_stage.AccountReportItem'))
BEGIN
    ALTER TABLE edw_stage.AccountReportItem ADD IsExternalShared bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Metadata' AND object_id = OBJECT_ID('edw_stage.AccountActivity'))
BEGIN
    ALTER TABLE edw_stage.AccountActivity ADD Metadata nvarchar(3500);
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'ProductLine' AND object_id = OBJECT_ID('edw_stage.DocumentType'))
BEGIN
    ALTER TABLE edw_stage.DocumentType ADD ProductLine nvarchar(200);
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'AddedByRule' AND object_id = OBJECT_ID('edw_stage.AccountSubjectivity'))
BEGIN
    ALTER TABLE edw_stage.AccountSubjectivity ADD AddedByRule bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'IsRenewalRequoted' AND object_id = OBJECT_ID('edw_stage.AccountTransaction'))
BEGIN
    ALTER TABLE edw_stage.AccountTransaction ADD IsRenewalRequoted bit;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'ExternalDocumentLink' AND object_id = OBJECT_ID('edw_stage.Document'))
BEGIN
    ALTER TABLE edw_stage.Document ADD ExternalDocumentLink nvarchar(1000);
END;