IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'wildfire_protection_enrollment_in'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD wildfire_protection_enrollment_in varchar(255) END;  

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'site_scheduling_contact_nm'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD site_scheduling_contact_nm varchar(255) END;  

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'site_scheduling_phone_no'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD site_scheduling_phone_no varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'site_scheduling_email'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD site_scheduling_email varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'emergency_contact_nm'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD emergency_contact_nm varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'emergency_contact_phone_no'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD emergency_contact_phone_no varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'emergency_contact_email'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD emergency_contact_email varchar(255) END;  