IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tpolicy'					
AND COLUMN_NAME = 'target_account'					
) BEGIN ALTER TABLE edw_core.tpolicy ADD target_account varchar(255) END