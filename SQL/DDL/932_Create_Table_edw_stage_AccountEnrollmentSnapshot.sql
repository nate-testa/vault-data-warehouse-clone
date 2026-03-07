IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'AccountEnrollmentSnapshot')
BEGIN
CREATE TABLE edw_stage.AccountEnrollmentSnapshot
(
[Id]                               [int] NOT NULL,
[AccountId]                        [uniqueidentifier] NOT NULL,
[UserId]                           [uniqueidentifier] NULL,
[EnrollmentFrequency]              [nvarchar](250) NULL,
[EnrollmentInitialStartDate]       [datetime2](7) NULL,
[EnrollmentPeriodByDays]           [int](4) NULL,
[OverrideEnrollmentToOpen]         [bit](1) NOT NULL,
[ExternalSourceId]                 [nvarchar](2000) NULL,
[ExternalSourceUniqueId]           [nvarchar](2000) NULL,
[CreatedDate]                      [datetime2](7) NOT NULL,
[UpdatedDate]                      [datetime2](7) NULL
);
END



/*
IF EXISTS
(SELECT 1 FROM edw_stage.tedw_table_detail
	where table_nm = 'AccountEnrollmentSnapshot')
BEGIN
	delete FROM edw_stage.tedw_table_detail
	where table_nm = 'AccountEnrollmentSnapshot' ; 
END ; 

INSERT INTO edw_stage.tedw_table_detail (
    table_nm,
    table_type,
    table_category_nm,
    domain_nm,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'AccountEnrollmentSnapshot',
    'Type-2 Dimension',
    'Base',
    'Group Personal Excess Liability',
    'Stored Procedure',
    'Insert',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_stage.tedw_table_detail
    WHERE table_nm = 'AccountEnrollmentSnapshot'
);

*/