IF NOT EXISTS (SELECT * FROM sys.objects 
               WHERE object_id = OBJECT_ID(N'[edw_stage].[CompanyTeam]') 
               AND type in (N'U'))
BEGIN
CREATE TABLE [edw_stage].[CompanyTeam](
	[Id] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](200) NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_CompanyTeam] PRIMARY KEY (Id) 
 )
 END
GO

IF NOT EXISTS (SELECT * FROM sys.objects 
               WHERE object_id = OBJECT_ID(N'[edw_stage].[CompanyTeamBrokerage]') 
               AND type in (N'U'))
BEGIN
CREATE TABLE [edw_stage].[CompanyTeamBrokerage](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CompanyTeamId] [uniqueidentifier] NOT NULL,
	[BrokerageId] [uniqueidentifier] NOT NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[ExternalSourceUniqueId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NULL,
 CONSTRAINT [PK_CompanyTeamBrokerage] PRIMARY KEY (Id))
 END
GO

IF NOT EXISTS (SELECT * FROM sys.objects 
               WHERE object_id = OBJECT_ID(N'[edw_stage].[CompanyTeamMember]') 
               AND type in (N'U'))
BEGIN
CREATE TABLE [edw_stage].[CompanyTeamMember](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CompanyTeamId] [uniqueidentifier] NOT NULL,
	[ProductId] [uniqueidentifier] NOT NULL,
	[State] [nvarchar](50) NULL,
	[ProgramType] [nvarchar](200) NULL,
	[TeamMemberType] [nvarchar](200) NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[ExternalSourceUniqueId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NULL,
 CONSTRAINT [PK_CompanyTeamMember] PRIMARY KEY (Id))
 END
GO