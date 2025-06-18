IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_core'                
AND TABLE_NAME = 'tbroker_license'                  
AND COLUMN_NAME = 'license_type'                    
) BEGIN ALTER TABLE edw_stage.tbroker_license ADD license_type VARCHAR(255) NULL END ; 

