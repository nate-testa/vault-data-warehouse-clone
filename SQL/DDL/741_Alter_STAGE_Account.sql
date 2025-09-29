IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA = 'edw_stage'                
AND TABLE_NAME = 'Account'                  
AND COLUMN_NAME = 'PremiumAnalyticsGrade'                    
) BEGIN ALTER TABLE edw_stage.Account ADD PremiumAnalyticsGrade nvarchar(250) NULL END ; 