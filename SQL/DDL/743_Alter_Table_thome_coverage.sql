IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'thome_coverage'                  
AND COLUMN_NAME = 'premium_analytics_grade'                    
) 
BEGIN 
    ALTER TABLE edw_core.thome_coverage ADD premium_analytics_grade VARCHAR(255) NULL
END ;