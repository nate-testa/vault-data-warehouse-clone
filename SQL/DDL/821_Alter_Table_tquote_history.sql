IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_history'					
AND COLUMN_NAME = 'indication_status'					
) BEGIN ALTER TABLE edw_core.tquote_history ADD indication_status Varchar(255) END ; 