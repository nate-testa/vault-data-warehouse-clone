IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_history'
    AND     COLUMN_NAME = 'premium_rater_version'
) BEGIN ALTER TABLE edw_core.tquote_history ADD premium_rater_version varchar(255) END ;