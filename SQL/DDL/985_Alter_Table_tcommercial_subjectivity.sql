IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_commercial'
AND TABLE_NAME = 'tcommercial_subjectivity'
AND COLUMN_NAME = 'subjectivity_desc'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_subjectivity ALTER COLUMN [subjectivity_desc] VARCHAR(4000);
END ;