IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'broker_hubspot_feed'					
AND COLUMN_NAME = 'primary_address_state_cd'					
) 
BEGIN ALTER TABLE edw_integration.broker_hubspot_feed ADD primary_address_state_cd varchar(255) END
 
 