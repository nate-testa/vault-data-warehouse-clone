IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'create_ts'
) 
BEGIN
    ALTER TABLE edw_core.tgrpel_coverage ALTER COLUMN create_ts Datetime2(7) 
END ; 


IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'update_ts'
) 
BEGIN
    ALTER TABLE edw_core.tgrpel_coverage ALTER COLUMN update_ts Datetime2(7) 
END ; 