IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_stage'
AND TABLE_NAME = 'AccountTransactionIssue'
AND COLUMN_NAME = 'ExternalApplyScope'
) 
BEGIN 
    ALTER TABLE edw_stage.AccountTransactionIssue ADD  ExternalApplyScope nvarchar(200) NULL
END ; 

