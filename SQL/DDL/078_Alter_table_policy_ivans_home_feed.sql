ALTER TABLE [edw_integration].[policy_ivans_home_feed] DROP CONSTRAINT [pk_policy_ivans_home_feed];

ALTER TABLE edw_integration.policy_ivans_home_feed ALTER COLUMN PolicyNumber_030 VARCHAR(255) NOT NULL;

ALTER TABLE [edw_integration].[policy_ivans_home_feed] ADD CONSTRAINT [pk_policy_ivans_home_feed] 
PRIMARY KEY ([PolicyNumber_030] , [EffectiveDt_034] ,[transaction_seq_no] );