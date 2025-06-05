--AD9713 - SR-38158 - Integrate Document delivery data into EDW--

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy '                  
AND COLUMN_NAME = 'document_delivery_to'                    
) BEGIN ALTER TABLE edw_core.tpolicy ADD document_delivery_to VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy '                  
AND COLUMN_NAME = 'document_delivery_method'                    
) BEGIN ALTER TABLE edw_core.tpolicy ADD document_delivery_method VARCHAR(255) NULL END ; 

