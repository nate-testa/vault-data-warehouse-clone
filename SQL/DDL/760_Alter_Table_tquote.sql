IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'renewal_released_by_metal_in'
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD renewal_released_by_metal_in VARCHAR(255) NULL
END ;