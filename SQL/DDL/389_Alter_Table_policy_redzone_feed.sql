IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'bdm_nm'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD bdm_nm varchar(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'new_business_underwriter_nm'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD new_business_underwriter_nm varchar(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'renewal_underwriter_nm'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD renewal_underwriter_nm varchar(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'effective_dt'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD effective_dt date END; 
 