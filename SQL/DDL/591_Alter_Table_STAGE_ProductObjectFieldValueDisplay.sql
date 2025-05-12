IF OBJECT_ID('edw_stage.ProductObjectFieldValueDisplay', 'U') IS NOT NULL
BEGIN
    DROP TABLE edw_stage.ProductObjectFieldValueDisplay;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [edw_stage].[ProductObjectFieldValueDisplay](
	[Id] [int] NOT NULL,
	[ProductId] [uniqueidentifier] NOT NULL,
	[EffectiveDate] [datetime2](7) NOT NULL,
	[ObjectType] [nvarchar](100) NULL,
	[Field] [nvarchar](250) NULL,
	[Value] [nvarchar](1000) NULL,
	[ValueDisplay] [nvarchar](1000) NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[ExternalSourceUniqueId] [nvarchar](2000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NULL,
	[StateCode] [nvarchar](10) NULL,
	[ExpirationDate] [datetime2](7) NULL,
	[ExternalVersionId] nvarchar(100) NULL,
	[IsRenewal] bit NOT NULL, 
	[Version] nvarchar(20) NULL
) ON [PRIMARY]
GO