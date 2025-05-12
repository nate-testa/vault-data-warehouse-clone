IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tpolicy_history'
    AND     COLUMN_NAME = 'premium_rater_version'
) BEGIN ALTER TABLE edw_core.tpolicy_history ADD premium_rater_version varchar(255) END ;