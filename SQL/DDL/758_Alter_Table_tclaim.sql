IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tclaim'                  
AND COLUMN_NAME = 'closed_reason_desc'                    
) BEGIN ALTER TABLE edw_core.tclaim ADD closed_reason_desc VARCHAR(255) NULL END ;