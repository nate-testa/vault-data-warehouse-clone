IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote'
    AND     COLUMN_NAME = 'close_reason_desc'
) BEGIN 
ALTER TABLE edw_core.tquote ADD close_reason_desc varchar(255);
END;