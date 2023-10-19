CREATE TABLE edw_stage.[AccountStatusHistory] (
    [Id] int NOT NULL ,
    [AccountId] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NULL,
    [Stage] nvarchar(200) NULL,
    [State] nvarchar(200) NULL,
    [ExternalSourceId] nvarchar(2000) NULL,
    [ExternalSourceUniqueId] nvarchar(2000) NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    CONSTRAINT [PK_AccountStatusHistory] PRIMARY KEY ([Id])
    );

CREATE TABLE edw_stage.[AccountTransactionStatusHistory] (
    [Id] int NOT NULL ,
    [AccountId] uniqueidentifier NOT NULL,
    [AccountTransactionId] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NULL,
    [Stage] nvarchar(200) NULL,
    [State] nvarchar(200) NULL,
    [ExternalSourceId] nvarchar(2000) NULL,
    [ExternalSourceUniqueId] nvarchar(2000) NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    CONSTRAINT [PK_AccountTransactionStatusHistory] PRIMARY KEY ([Id])
);

ALTER TABLE edw_stage.[BillingAccount] ADD [IsUserCreated] bit DEFAULT CAST(0 AS bit)

-- Indexes

CREATE INDEX [IX_AccountStatusHistory_AccountId] ON edw_stage.[AccountStatusHistory] ([AccountId]);
CREATE INDEX [IX_AccountTransactionStatusHistory_AccountId] ON edw_stage.[AccountTransactionStatusHistory] ([AccountId]);
CREATE INDEX [IX_AccountTransactionStatusHistory_AccountTransactionId] ON edw_stage.[AccountTransactionStatusHistory] ([AccountTransactionId]);


