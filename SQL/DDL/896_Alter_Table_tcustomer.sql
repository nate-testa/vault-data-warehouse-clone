IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tcustomer'
AND COLUMN_NAME = 'subscriber_contribution_end_dt'
) 
BEGIN 
    ALTER TABLE edw_core.tcustomer ADD subscriber_contribution_end_dt   date NULL
END ; 