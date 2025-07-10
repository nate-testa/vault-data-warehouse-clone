IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'broker_hubspot_feed'					
AND COLUMN_NAME = 'broker_business_type'		
) BEGIN ALTER TABLE edw_integration.broker_hubspot_feed ADD broker_business_type varchar(255) END			 
;  

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'broker_hubspot_feed'					
AND COLUMN_NAME = 'quote_to_bind_ratio'		
) BEGIN ALTER TABLE edw_integration.broker_hubspot_feed ADD quote_to_bind_ratio decimal(15,2) END			 
;  

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'broker_hubspot_feed'					
AND COLUMN_NAME = 'submission_to_quote_ratio'		
) BEGIN ALTER TABLE edw_integration.broker_hubspot_feed ADD submission_to_quote_ratio decimal(15,2) END			 
; 
 