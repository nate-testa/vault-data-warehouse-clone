IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_auto_vehicle'
    AND     COLUMN_NAME = 'vehicle_unique_id'
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle ADD vehicle_unique_id varchar(255) end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_auto_vehicle'
    AND     COLUMN_NAME = 'vehicle_vin_invalid_message'
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle ADD vehicle_vin_invalid_message nvarchar(max) end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_auto_vehicle'
    AND     COLUMN_NAME = 'vehicle_vin_invalid_in'
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle ADD vehicle_vin_invalid_in      varchar(255) end;

/*ALTER TABLE [edw_core].[tquote_auto_vehicle] drop CONSTRAINT [uidx_tquote_auto_vehicle_qtno_vehicleno]; 

ALTER TABLE [edw_core].[tquote_auto_vehicle] ADD CONSTRAINT [uidx_tquote_auto_vehicle_qtno_vehicle_unique_id] 
UNIQUE (quote_no,effective_dt,vehicle_unique_id);
*/



