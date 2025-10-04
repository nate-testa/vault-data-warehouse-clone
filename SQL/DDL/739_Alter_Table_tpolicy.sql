IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tpolicy'					
AND COLUMN_NAME = 'policy_inforce_in'					
) BEGIN ALTER TABLE edw_core.tpolicy ADD policy_inforce_in varchar(255) END