IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'account'					
AND COLUMN_NAME = 'IsReleasedByMetal'					
) BEGIN ALTER TABLE edw_stage.account ADD IsReleasedByMetal bit END 	