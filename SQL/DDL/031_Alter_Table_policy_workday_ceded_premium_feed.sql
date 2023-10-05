ALTER TABLE [edw_integration].[policy_workday_ceded_premium_feed] DROP CONSTRAINT pk_policy_workday_ceded_premium_feed;

ALTER TABLE [edw_integration].[policy_workday_ceded_premium_feed] ADD financial_category_id varchar(255) NOT NULL;

ALTER TABLE [edw_integration].[policy_workday_ceded_premium_feed] ADD CONSTRAINT pk_policy_workday_ceded_premium_feed PRIMARY KEY 
([accounting_date],	[policy_number],[effective_date] ,[transaction_sequence] ,[financial_category_id] )
;