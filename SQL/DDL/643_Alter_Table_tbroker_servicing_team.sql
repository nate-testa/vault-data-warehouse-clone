IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tbroker_servicing_team'					
AND COLUMN_NAME = 'id'					
) 
BEGIN 
ALTER TABLE edw_core.tbroker_servicing_team ADD id uniqueidentifier NOT NULL 
END ; 