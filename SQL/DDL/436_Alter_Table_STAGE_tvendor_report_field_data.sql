IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'tvendor_report_field_data'
    AND     COLUMN_NAME = 'IsReportFromCache'
) BEGIN ALTER TABLE edw_stage.tvendor_report_field_data ADD IsReportFromCache varchar(255) END;  