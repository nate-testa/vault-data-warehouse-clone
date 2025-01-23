
IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'thome_coverage'
    AND     COLUMN_NAME = 'fenced_pool_in'
) BEGIN ALTER TABLE edw_core.thome_coverage ADD fenced_pool_in varchar(255);