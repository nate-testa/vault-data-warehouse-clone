IF NOT EXISTS (      
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tclaim'
AND COLUMN_NAME = 'facts_of_loss'
)
BEGIN 
    ALTER TABLE edw_core.tclaim ADD facts_of_loss nvarchar(max) NULL
END ;