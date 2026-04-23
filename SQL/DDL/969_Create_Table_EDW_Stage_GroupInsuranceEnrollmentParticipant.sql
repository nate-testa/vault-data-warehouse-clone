IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'GroupInsuranceEnrollmentParticipant')
BEGIN 
CREATE TABLE [dbo].[GroupInsuranceEnrollmentParticipant](
	[Id] [uniqueidentifier] NOT NULL,
	[GroupInsuranceId] [uniqueidentifier] NOT NULL,
	[AccountId] [uniqueidentifier] NULL,
	[FirstName] [nvarchar](200) NULL,
	[LastName] [nvarchar](200) NULL,
	[Email] [nvarchar](320) NULL,
	[Tier] [nvarchar](200) NULL,
	[EnrollmentStatus] [nvarchar](50) NULL,
	[IsDeleted] [bit] NOT NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL
);
END 