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
[EnrollmentPeriodByDays]           [int] NULL,
[OverrideEnrollmentToOpen]         [bit] NOT NULL,
[ExternalSourceId]                 [nvarchar](2000) NULL,
[ExternalSourceUniqueId]           [nvarchar](2000) NULL,
[CreatedDate]                      [datetime2](7) NOT NULL,
[UpdatedDate]                      [datetime2](7) NULL
);
END
