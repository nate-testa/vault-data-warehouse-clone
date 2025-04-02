IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'AccountSubjectivity'
    AND     COLUMN_NAME = 'IsDeleted'
)
BEGIN
ALTER TABLE [edw_stage].[AccountSubjectivity] ADD [IsDeleted] bit NOT NULL
END ;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'AccountSubjectivity'
    AND     COLUMN_NAME = 'AddedByUserId'
)
BEGIN
ALTER TABLE [edw_stage].[AccountSubjectivity] ADD [AddedByUserId] uniqueidentifier NULL
END ;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'AccountSubjectivity'
    AND     COLUMN_NAME = 'CompletedByUserId'
)
BEGIN
ALTER TABLE [edw_stage].[AccountSubjectivity] ADD [CompletedByUserId] uniqueidentifier NULL
END ;