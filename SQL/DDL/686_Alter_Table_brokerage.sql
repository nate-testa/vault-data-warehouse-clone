IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'brokerage'                  
AND COLUMN_NAME = 'CanAccessCommercialProducts'                    
) BEGIN ALTER TABLE edw_stage.brokerage ADD CanAccessCommercialProducts nvarchar(100) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'brokerage'                  
AND COLUMN_NAME = 'CanAccessPersonalProducts'                    
) BEGIN ALTER TABLE edw_stage.brokerage ADD CanAccessPersonalProducts nvarchar(100) NULL END ; 

