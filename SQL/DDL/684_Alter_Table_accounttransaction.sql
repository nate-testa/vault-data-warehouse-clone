IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_stage'                
AND TABLE_NAME = 'accounttransaction'                  
AND COLUMN_NAME = 'BoundByUserId'                    
) BEGIN ALTER TABLE edw_stage.accounttransaction ADD BoundByUserId  nvarchar(100) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_stage'                
AND TABLE_NAME = 'accounttransaction'                  
AND COLUMN_NAME = 'IssuedByUserId'                    
) BEGIN ALTER TABLE edw_stage.accounttransaction ADD IssuedByUserId  nvarchar(100) NULL END ; 
