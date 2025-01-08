IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_transaction'
    AND     COLUMN_NAME = 'quote_collection_class_type_sk'
) BEGIN ALTER TABLE edw_core.tquote_transaction ADD quote_collection_class_type_sk int DEFAULT 0 END;
 