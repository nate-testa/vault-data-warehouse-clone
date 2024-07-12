IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_auto_vehicle'
    AND     COLUMN_NAME = 'vehicle_unique_id'
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle ADD vehicle_unique_id varchar(255) end;

ALTER TABLE edw_core.tquote_auto_vehicle  
DROP CONSTRAINT uidx_tquote_auto_vehicle_qtno_vehicleno;
