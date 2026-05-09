IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'GroupInsurance')
BEGIN 
CREATE TABLE edw_stage.[GroupInsurance]
(
	[Id] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](2000) NULL,
	[GroupAdmin] [uniqueidentifier] NOT NULL,
	[GroupAccountId] [uniqueidentifier] NOT NULL,
	[ParticipantProductId] [uniqueidentifier] NOT NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL,
	[LogoBlobContainer] [nvarchar](200) NULL,
	[LogoBlobIdentifier] [nvarchar](200) NULL,
	[EnrollmentValidationFileBlobContainer] [nvarchar](200) NULL,
	[EnrollmentValidationFileBlobIdentifier] [nvarchar](200) NULL
);
END 

