IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'policy_ivans_home_feed'
      AND COLUMN_NAME = 'InsurerId_063'
)
BEGIN
	ALTER TABLE [edw_integration].[policy_ivans_home_feed] ALTER COLUMN InsurerId_063 varchar(255); 
END;