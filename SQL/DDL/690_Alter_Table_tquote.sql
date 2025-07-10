IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote'					
AND COLUMN_NAME = 'renewal_cap_factor'					
) BEGIN ALTER TABLE edw_core.tquote ADD renewal_cap_factor decimal(16,4) END