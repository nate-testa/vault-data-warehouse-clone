IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_core'                
AND TABLE_NAME = 'tbroker'                  
AND COLUMN_NAME = 'commercial_or_personal_business_type'                    
) BEGIN ALTER TABLE edw_core.tbroker ADD commercial_or_personal_business_type varchar(255) NULL END ; 
