IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'ttask'                  
AND COLUMN_NAME = 'task_id'                    
) BEGIN ALTER TABLE edw_core.ttask ADD task_id VARCHAR(255) NULL END ; 

CREATE UNIQUE NONCLUSTERED INDEX uidx_ttask_task_id ON edw_core.ttask(task_id);
 
 