IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy_history '                  
AND COLUMN_NAME = 'cancellation_sub_reason_desc'                    
) BEGIN ALTER TABLE edw_core.tpolicy_history ADD cancellation_sub_reason_desc VARCHAR(255) END ; 