IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'thome_additional_coverage'
AND COLUMN_NAME = 'risk_sharing_deductible_pc'
) 
BEGIN 
    ALTER TABLE edw_core.thome_additional_coverage ADD risk_sharing_deductible_pc VARCHAR(255) NULL 
END 