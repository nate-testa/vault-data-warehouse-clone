IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'Broker'                  
AND COLUMN_NAME = 'Status'                    
) BEGIN ALTER TABLE edw_stage.Broker ADD Status nvarchar(200) NULL END ; 

