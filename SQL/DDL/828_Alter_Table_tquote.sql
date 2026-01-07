IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'current_producer_nm'
) 
BEGIN 
    ALTER TABLE edw_core.tpolicy ADD current_producer_nm  VARCHAR(255) NULL
END ; 

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'current_underwriter_nm'
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD current_underwriter_nm   VARCHAR(255) NULL
END ; 