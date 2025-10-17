IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tpel_watercraft'
AND COLUMN_NAME = 'watercraft_unique_id'
) 
BEGIN 
    ALTER TABLE edw_core.tpel_watercraft ADD watercraft_unique_id VARCHAR(255) NULL
END ;