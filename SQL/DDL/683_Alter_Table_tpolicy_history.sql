IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy_history'                  
AND COLUMN_NAME = 'transaction_bound_by_user_nm'                    
) BEGIN ALTER TABLE edw_core.tpolicy_history ADD transaction_bound_by_user_nm  VARCHAR(255) NULL END ; 
