IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed '                  
AND COLUMN_NAME = 'document_delivery_preference'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD document_delivery_preference VARCHAR(255) NULL END ;  