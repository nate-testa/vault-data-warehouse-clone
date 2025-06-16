IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'BrokerageLicense'                  
AND COLUMN_NAME = 'LicenseType'                    
) BEGIN ALTER TABLE edw_stage.BrokerageLicense ADD LicenseType nvarchar(1000) NULL END ; 

