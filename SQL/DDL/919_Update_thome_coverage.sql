IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'thome_coverage'
AND COLUMN_NAME = 'frame_to_foundation_connection_in'
) 
BEGIN 
    ALTER TABLE edw_core.thome_coverage ADD frame_to_foundation_connection_in Varchar(255) NULL
END ; 