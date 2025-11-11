IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'broker_of_record_change_in'
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD broker_of_record_change_in VARCHAR(255) NULL
END ;