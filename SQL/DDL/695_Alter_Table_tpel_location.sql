IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tpel_location'					
AND COLUMN_NAME = 'location_deleted_in'					
) BEGIN ALTER TABLE edw_core.tpel_location ADD location_deleted_in varchar(255) END