IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tpolicy_referral_message'
AND COLUMN_NAME = 'external_apply_scope'
) 
BEGIN 
    ALTER TABLE edw_core.tpolicy_referral_message ADD external_apply_scope Varchar(255) NULL
END ; 

