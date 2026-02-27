IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_additional_interest'
AND COLUMN_NAME = 'additional_interest_nm'
) 
BEGIN 
	ALTER TABLE edw_core.tquote_additional_interest ALTER COLUMN additional_interest_nm VARCHAR(2000) NULL
END; 
