IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionFieldExpressionValidation' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionFieldExpressionValidation (
        Id int,
        ExcelProductServiceVersionId int,
        ObjectType nvarchar(200),
        Field nvarchar(200),
        FieldValue nvarchar(200),
        SheetName nvarchar(100),
        Cell nvarchar(10),
        Validation nvarchar(200),
        Error nvarchar(3800),
        IsValid bit,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        Action nvarchar(200),
        Expression nvarchar(3800),
        FieldValueDisplay nvarchar(200)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AccountWorkflowEventLog' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.AccountWorkflowEventLog (
        Id uniqueidentifier,
        AccountId uniqueidentifier,
        AccountTransactionId uniqueidentifier,
        PreviousStage nvarchar(50),
        Stage nvarchar(50),
        PreviousState nvarchar(50),
        State nvarchar(50),
        TriggeredByInternalUser bit,
        WorkflowEventType nvarchar(200),
        WorkflowStepFound bit,
        TaskCreated bit,
        ExternalSourceId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        RetryEvent bit,
        UnderwriterUserId uniqueidentifier
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServicePublishRequirement' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServicePublishRequirement (
        Id uniqueidentifier,
        ServiceType nvarchar(200),
        Role nvarchar(200),
        ExternalSourceId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        Label nvarchar(50),
        LabelView nvarchar(10)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRole' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.UserRole (
        Id int,
        UserId uniqueidentifier,
        RoleId int,
        RoleName nvarchar(250),
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionDifference' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionDifference (
        Id int,
        ExcelProductServiceVersionId int,
        SheetName nvarchar(100),
        Cell nvarchar(50),
        CurrentValue nvarchar(3800),
        OldValue nvarchar(3800),
        ChangeType nvarchar(200),
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionFieldValueChange' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionFieldValueChange (
        Id int,
        ExcelProductServiceVersionId int,
        ObjectType nvarchar(200),
        Field nvarchar(200),
        SheetName nvarchar(100),
        Cell nvarchar(10),
        Action nvarchar(200),
        Value nvarchar(3800),
        IsValid bit,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BillingAccountHistory' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.BillingAccountHistory (
        Id int,
        BillingAccountId uniqueidentifier,
        TransactionType nvarchar(200),
        UserName nvarchar(100),
        NewValue nvarchar(500),
        OldValue nvarchar(500),
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        IsUpdatedByInternalUser bit
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionPublishRequirement' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionPublishRequirement (
        Id int,
        ExcelProductServiceVersionId int,
        Role nvarchar(200),
        IsCompleted bit,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        Label nvarchar(50),
        LabelView nvarchar(10)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionError' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionError (
        Id int,
        ExcelProductServiceVersionId int,
        Error nvarchar(1000),
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionPublishOverrideFeedBack' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionPublishOverrideFeedBack (
        Id int,
        ExcelProductServiceVersionId int,
        FeedBack nvarchar(200),
        UserId uniqueidentifier,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkTaskReference' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.WorkTaskReference (
        Id int,
        WorkTaskId uniqueidentifier,
        BlobIdentifier nvarchar(300),
        Extension nvarchar(20),
        ReferenceUrl nvarchar(2000),
        ReferenceType nvarchar(200),
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notification' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.Notification (
        Id int,
        Type nvarchar(200),
        IsRead bit,
        UserId nvarchar(50),
        TriggeredById uniqueidentifier,
        Message nvarchar(1000),
        SourceUrl nvarchar(1000),
        RelatedEntityId uniqueidentifier,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersion' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersion (
        Id int,
        ExcelProductServiceId uniqueidentifier,
        ExternalVersionId nvarchar(50),
        Version nvarchar(50),
        OriginalBlobIdentifier nvarchar(200),
        FileName nvarchar(200),
        Note nvarchar(2000),
        EffectiveDate datetime2,
        RenewalEffectiveDate datetime2,
        VersionStatus nvarchar(200),
        StagedByUserId uniqueidentifier,
        PublishedByUserId uniqueidentifier,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        DeletedByUserId uniqueidentifier,
        DeletedDate datetime2,
        DeletionReason nvarchar(200),
        IsDeleted bit,
        IsReadyToPublish bit,
        IsTestedByUserId uniqueidentifier
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductService' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductService (
        Id uniqueidentifier,
        ExcelProductId uniqueidentifier,
        Name nvarchar(200),
        Category nvarchar(200),
        Type nvarchar(200),
        Description nvarchar(200),
        ExternalSourceId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        DeletedByUserId uniqueidentifier,
        DeletedDate datetime2,
        DeletionReason nvarchar(200),
        IsDeleted bit
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionSchemaValidation' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionSchemaValidation (
        Id int,
        ExcelProductServiceVersionId int,
        ObjectType nvarchar(200),
        Field nvarchar(200),
        SheetName nvarchar(100),
        Cell nvarchar(10),
        Action nvarchar(200),
        Property nvarchar(200),
        Value nvarchar(3800),
        IsValid bit,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2,
        OldValue nvarchar(3800)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProductServiceVersionPublishRequirementFeedBack' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProductServiceVersionPublishRequirementFeedBack (
        Id int,
        ExcelProductServiceVersionRoleRequirementId int,
        FeedBack nvarchar(200),
        UserId uniqueidentifier,
        ExternalSourceId nvarchar(2000),
        ExternalSourceUniqueId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelProduct' AND schema_name(schema_id) = 'edw_stage')
BEGIN
    CREATE TABLE edw_stage.ExcelProduct (
        Id uniqueidentifier,
        ProductId uniqueidentifier,
        IsProductService bit,
        Name nvarchar(200),
        ExternalSourceId nvarchar(2000),
        CreatedDate datetime2,
        UpdatedDate datetime2
    );
END;