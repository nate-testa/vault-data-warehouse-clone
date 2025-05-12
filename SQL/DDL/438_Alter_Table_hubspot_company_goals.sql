

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE type IN ('PK', 'UQ')  -- PK for Primary Key, UQ for Unique
      AND name = 'pk_hubspot_company_goals'
)
BEGIN
  ALTER TABLE [edw_stage].[hubspot_company_goals] DROP CONSTRAINT [pk_hubspot_company_goals];
END

