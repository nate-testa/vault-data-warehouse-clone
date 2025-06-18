IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'customer_hubspot_feed'                  
AND COLUMN_NAME = 'product_cd'                    
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD product_cd VARCHAR(255) NULL END ;  
 