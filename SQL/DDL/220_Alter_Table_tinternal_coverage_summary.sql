IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tinternal_coverage_summary'
    AND     COLUMN_NAME = 'collection_class_type_sk'
) BEGIN ALTER TABLE edw_core.tinternal_coverage_summary ADD collection_class_type_sk int DEFAULT 0 END;