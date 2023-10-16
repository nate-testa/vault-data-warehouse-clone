
ALTER TABLE [edw_stage].[BillingAccount] DROP CONSTRAINT DF__BillingAc__Refer__34F6245F;

ALTER TABLE [edw_stage].[BillingAccount] ALTER COLUMN [ReferenceCode] nvarchar(1000) NOT NULL;


