IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_coverage'
    AND     COLUMN_NAME = 'nc_bureau_rate'
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD nc_bureau_rate varchar(255) null END;  