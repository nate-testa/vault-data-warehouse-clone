IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tpolicy'
AND COLUMN_NAME = 'bor_change_In'
) 
BEGIN 
    ALTER TABLE edw_core.tpolicy ADD bor_change_In VARCHAR(255) NULL
END ;