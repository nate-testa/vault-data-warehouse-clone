IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tclaim '                  
AND COLUMN_NAME = 'first_party_driver_relationship_to_insured'                    
) BEGIN ALTER TABLE edw_core.tclaim ADD first_party_driver_relationship_to_insured VARCHAR(255) NULL END ; 