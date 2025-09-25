IF NOT EXISTS (      
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tclaim'
AND COLUMN_NAME = 'large_loss_in'
)
BEGIN 
    ALTER TABLE edw_core.tclaim ADD large_loss_in varchar(255) NULL
END ;