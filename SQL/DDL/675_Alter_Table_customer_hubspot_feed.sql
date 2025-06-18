
 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_line_1'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_line_1 VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_line_2'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_line_2 VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_unit_no'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_unit_no VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_city_nm'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_city_nm VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_state_cd'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_state_cd VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'quote_hubspot_feed'                  
AND COLUMN_NAME = 'mailing_address_zip_cd'                    
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD mailing_address_zip_cd VARCHAR(255) NULL END ; 

