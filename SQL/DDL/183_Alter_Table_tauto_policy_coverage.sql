IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tauto_policy_coverage'
    AND COLUMN_NAME = 'collision_ncrb_premium_amt'
) BEGIN ALTER TABLE edw_core.tauto_policy_coverage ADD collision_ncrb_premium_amt varchar(255) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tauto_policy_coverage'
    AND COLUMN_NAME = 'otc_ncrb_premium_amt'
) BEGIN ALTER TABLE edw_core.tauto_policy_coverage ADD otc_ncrb_premium_amt varchar(255) null END; 
