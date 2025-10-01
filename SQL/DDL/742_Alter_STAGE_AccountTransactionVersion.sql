IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'AccountTransactionVersion'                  
AND COLUMN_NAME = 'PremiumAnalyticsGrade'                    
) BEGIN ALTER TABLE edw_stage.AccountTransactionVersion ADD PremiumAnalyticsGrade nvarchar(250) NULL END ; 
