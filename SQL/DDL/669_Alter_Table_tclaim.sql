IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_core'                
AND TABLE_NAME = 'tclaim'                  
AND COLUMN_NAME = 'litigation_in'                    
) BEGIN ALTER TABLE edw_core.tclaim ADD litigation_in VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_core'                
AND TABLE_NAME = 'tclaim'                  
AND COLUMN_NAME = 'litigation_complete_in'                    
) BEGIN ALTER TABLE edw_core.tclaim ADD litigation_complete_in VARCHAR(255) NULL END ; 

