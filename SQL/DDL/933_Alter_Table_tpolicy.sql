IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tpolicy'
AND COLUMN_NAME = 'grpel_master_policy_no'
) 
BEGIN 
    ALTER TABLE edw_core.tpolicy ADD grpel_master_policy_no  varchar(255) NULL
END ; 


