IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_coverage'
    AND     COLUMN_NAME = 'rate_on_line'
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD rate_on_line decimal(15,2) null END;  