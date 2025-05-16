IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'broker_state'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD broker_state varchar(255) END			 
; 