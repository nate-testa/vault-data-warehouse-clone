IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tadditional_interest'
AND COLUMN_NAME = 'residence_owned_by_trust_in'
) 
BEGIN 
    ALTER TABLE edw_core.tadditional_interest ADD residence_owned_by_trust_in Varchar(255) NULL
END ; 