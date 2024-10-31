IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_collection_scheduled_item'
    AND     COLUMN_NAME = 'scheduled_item_deleted_in'
) BEGIN ALTER TABLE edw_core.tquote_collection_scheduled_item ADD scheduled_item_deleted_in varchar(255) END;    