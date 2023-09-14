
-- Create Master Key and scoped credentials

CREATE MASTER KEY;
CREATE DATABASE SCOPED CREDENTIAL external_source_metal_uat
WITH IDENTITY = 'CloudSAcc6c431a', SECRET = 'VltsqlA4&';

-- Create External Data Source

CREATE EXTERNAL DATA SOURCE metaldb_uat WITH ( TYPE=RDBMS, LOCATION='azrvaultmetaluat001.database.windows.net', DATABASE_NAME='metaldb', CREDENTIAL= external_source_metal_uat );


 -- Create Exteral Table AccountTransaction

CREATE EXTERNAL TABLE [dbo].[AccountTransaction](
	[Id] [uniqueidentifier] NOT NULL,
	[AccountId] [uniqueidentifier] NOT NULL,
	[ProductId] [uniqueidentifier] NOT NULL,
	[EffectiveDate] [datetime2](7) NULL,
	[ExpirationDate] [datetime2](7) NULL,
	[Stage] [nvarchar](200) NULL,
	[State] [nvarchar](200) NULL,
	[Number] [int] NOT NULL,
	[PolicyChangeNumber] [int] NOT NULL,
	[TransactionEffectiveDate] [datetime2](7) NULL,
	[ProRateFactor] [decimal](16, 4) NOT NULL,
	[MinimumEarnedPremiumPercent] [int] NOT NULL,
	[TotalPremium] [decimal](16, 4) NOT NULL,
	[GrossPremiumOverride] [decimal](16, 4) NULL,
	[GrossPremiumDeltaProRatedOverride] [decimal](16, 4) NULL,
	[NetPremium] [decimal](16, 4) NOT NULL,
	[Commission] [decimal](16, 4) NOT NULL,
	[GrossPremiumDeltaProRated] [decimal](16, 4) NULL,
	[NetPremiumDeltaProRated] [decimal](16, 4) NULL,
	[CommissionDeltaProRated] [decimal](16, 4) NULL,
	[CommissionPercent] [decimal](16, 4) NOT NULL,
	[Cleared] [bit] NOT NULL,
	[Referred] [bit] NOT NULL,
	[IsLatestBoundTransaction] [bit] NOT NULL,
	[IsHidden] [bit] NOT NULL,
	[Note] [nvarchar](1000) NULL,
	[NotTakenReason] [nvarchar](2000) NULL,
	[CancellationReason] [nvarchar](2000) NULL,
	[PolicyChangeNotes] [nvarchar](max) NULL,
	[BindDate] [datetime2](7) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL,
	[GrossPremium] [decimal](16, 4) NOT NULL,
	[PreBindComplete] [bit] NOT NULL,
	[ReferredByUserId] [uniqueidentifier] NULL,
	[SubmitById] [uniqueidentifier] NULL,
	[CreatedById] [nvarchar](120) NULL,
	[ReviewedById] [uniqueidentifier] NULL,
	[ApproveNote] [nvarchar](2000) NULL,
	[DenyNote] [nvarchar](2000) NULL,
	[IsRevision] [bit] NOT NULL,
	[QuoteNote] [nvarchar](2000) NULL,
	[ExternalSourceId] [nvarchar](2000) NULL,
	[TotalPremiumDeltaProRated] [decimal](18, 2) NULL,
	[CommissionDelta] [decimal](16, 4) NULL,
	[GrossPremiumDelta] [decimal](16, 4) NULL,
	[NetPremiumDelta] [decimal](16, 4) NULL,
	[TotalPremiumDelta] [decimal](16, 4) NULL,
	[SubmitToBindById] [uniqueidentifier] NULL,
	[PolicyChangeGeneratedNotes] [nvarchar](max) NULL,
	[PolicyNumber] [nvarchar](25) NULL,
	[NotTakenNote] [nvarchar](3000) NULL,
	[IssuedDate] [datetime2](7) NULL,
	[PreviousStage] [nvarchar](200) NULL,
	[PreviousState] [nvarchar](200) NULL,
	[IsReversal] [bit] NOT NULL,
	[IsReversed] [bit] NOT NULL,
	[ReversalOfTransactionId] [uniqueidentifier] NULL,
	[IsExternallySubmitted] [bit] NOT NULL,
	[TransactionReferenceCode] [nvarchar](100) NULL,
	[StateUpdateDate] [datetime2](7) NOT NULL,
	[IsRenewal] [bit] NOT NULL
) 
WITH
  (
  DATA_SOURCE = metaldb_uat
  );




