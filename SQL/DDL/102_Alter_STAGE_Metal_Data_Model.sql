IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'Account'
      AND COLUMN_NAME = 'CopyOfAccountNumber'
)
BEGIN
	ALTER TABLE [edw_stage].[Account] ALTER COLUMN CopyOfAccountNumber nvarchar(25); 
END;