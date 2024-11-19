IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_pel_driver_incident'
    AND     COLUMN_NAME = 'driver_incident_unique_id'
) BEGIN ALTER TABLE edw_core.tquote_pel_driver_incident ADD driver_incident_unique_id varchar(255) END;
 