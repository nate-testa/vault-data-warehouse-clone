ALTER TABLE [edw_integration].[policy_workday_written_premium_feed] DROP CONSTRAINT [pk_policy_workday_written_premium_feed]
GO

ALTER TABLE [edw_integration].[policy_workday_written_premium_feed] ALTER COLUMN [Category] varchar(255) NOT NULL
GO

ALTER TABLE [edw_integration].[policy_workday_written_premium_feed] ADD  CONSTRAINT [pk_policy_workday_written_premium_feed] PRIMARY KEY CLUSTERED 
(
	[accounting_date] ASC,
	[policy_number] ASC,
	[effective_date] ASC,
	[Category] ASC,
	[transaction_sequence] ASC,
	[financial_category_id] ASC
) ON [PRIMARY]
GO
