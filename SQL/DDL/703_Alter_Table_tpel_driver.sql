IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tpel_driver'					
AND COLUMN_NAME = 'driver_status'					
) BEGIN ALTER TABLE edw_core.tpel_driver ADD driver_status varchar(255) END 