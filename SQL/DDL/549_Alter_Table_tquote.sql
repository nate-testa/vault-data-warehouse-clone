IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote'					
AND COLUMN_NAME = 'competitor_carrier_nm'					
) BEGIN ALTER TABLE edw_core.tquote ADD competitor_carrier_nm varchar(255) END 					
					
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote'					
AND COLUMN_NAME = 'close_reason_other_desc'					
) BEGIN ALTER TABLE edw_core.tquote ADD close_reason_other_desc nvarchar(3000) END	 