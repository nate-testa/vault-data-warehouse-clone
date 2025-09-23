IF NOT EXISTS (      
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tclaim'
AND COLUMN_NAME = 'loss_location_desc'
)
BEGIN 
    ALTER TABLE edw_core.tclaim ADD loss_location_desc nvarchar(max) NULL
END ;