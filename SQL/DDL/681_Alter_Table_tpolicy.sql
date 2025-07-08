IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy'                  
AND COLUMN_NAME = 'bound_by_broker_in'                    
) BEGIN ALTER TABLE edw_core.tpolicy ADD bound_by_broker_in VARCHAR(255) NULL END ; 
