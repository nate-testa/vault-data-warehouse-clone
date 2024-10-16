SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'lc360_temp_table' AND schema_name(schema_id) = 'edw_cat_model')
BEGIN
  CREATE TABLE [edw_cat_model].[lc360_temp_table](
  	[inspection_update_dt] [varchar](10) NOT NULL,
  	[inspectionNumber] [int] NULL,
  	[policyNumber] [varchar](50) NULL,
  	[status] [varchar](50) NULL,
  	[inspectionType] [varchar](50) NULL,
  	[QARepresentative] [varchar](50) NULL,
  	[firstTimeQAComplete_dt] [varchar](50) NULL,
  	[received_dt] [varchar](50) NULL,
  	[firstFieldComplete_dt] [varchar](50) NULL,
  	[completed_dt] [varchar](50) NULL,
  	[policyHolderFirstName] [varchar](50) NULL,
  	[policyHolderLastName] [varchar](50) NULL,
  	[VIP] [varchar](50) NULL,
  	[effective_dt] [varchar](50) NULL,
  	[covA_in] [int] NULL,
  	[covA_out] [int] NULL,
  	[covA_diff] [int] NULL,
  	[covB] [int] NULL,
  	[isDuplicate] [varchar](50) NULL,
  	[totalAccountPremium] [real] NULL,
  	[locationStreet] [varchar](50) NULL,
  	[locationCity] [varchar](50) NULL,
  	[locationState] [varchar](50) NULL,
  	[locationZip] [int] NULL,
  	[underwriter] [varchar](50) NULL,
  	[agency] [varchar](128) NULL,
  	[consultant] [varchar](50) NULL,
  	[orderedBy] [varchar](50) NULL,
  	[inspectionDue_dt] [varchar](50) NULL
  ) ON [PRIMARY]
END;
GO