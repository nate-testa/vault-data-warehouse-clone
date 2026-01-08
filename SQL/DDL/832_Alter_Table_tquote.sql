IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'current_producer_sk'
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD current_producer_sk   int NULL
END ; 