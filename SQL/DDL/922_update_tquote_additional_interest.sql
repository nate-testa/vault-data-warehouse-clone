IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_additional_interest'
AND COLUMN_NAME = 'residence_owned_by_trust_in'
) 
BEGIN 
    ALTER TABLE edw_core.tquote_additional_interest ADD residence_owned_by_trust_in Varchar(255) NULL
END ; 