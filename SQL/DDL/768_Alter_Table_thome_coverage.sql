IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'thome_coverage'
AND COLUMN_NAME = 'underwriter_required_inspection'
) 
BEGIN 
    ALTER TABLE edw_core.thome_coverage ADD underwriter_required_inspection VARCHAR(255) NULL
END ;