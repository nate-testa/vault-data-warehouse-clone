IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote'
    AND     COLUMN_NAME = 'stalled_quote_in'
) BEGIN ALTER TABLE edw_core.tquote ADD stalled_quote_in varchar(255) END ;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote'
    AND     COLUMN_NAME = 'new_business_work_status'
) BEGIN ALTER TABLE edw_core.tquote ADD new_business_work_status varchar(255) END ;