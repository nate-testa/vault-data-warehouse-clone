IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote_history'                  
AND COLUMN_NAME = 'bound_by_user_nm'                    
) BEGIN ALTER TABLE edw_core.tquote_history ADD bound_by_user_nm VARCHAR(255) NULL END ; 


IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote_history'                  
AND COLUMN_NAME = 'issued_by_user_nm'                    
) BEGIN ALTER TABLE edw_core.tquote_history ADD  issued_by_user_nm VARCHAR(255) NULL END ; 
