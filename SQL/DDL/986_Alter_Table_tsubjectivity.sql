IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tsubjectivity'
AND COLUMN_NAME = 'subjectivity_desc'
)
BEGIN
    ALTER TABLE edw_core.tsubjectivity ALTER COLUMN [subjectivity_desc] VARCHAR(4000);
END ;