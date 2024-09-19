IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'policy_redzone_feed'
    AND     COLUMN_NAME = 'producer_email'
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD producer_email varchar(255) END;  