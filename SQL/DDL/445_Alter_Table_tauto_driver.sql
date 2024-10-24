IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tauto_driver'
    AND     COLUMN_NAME = 'excluded_driver_in'
) BEGIN ALTER TABLE edw_core.tauto_driver ADD excluded_driver_in varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tauto_driver'
    AND     COLUMN_NAME = 'excluded_driver_for_all_vehicles_in'
) BEGIN ALTER TABLE edw_core.tauto_driver ADD excluded_driver_for_all_vehicles_in varchar(255) END;   

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tauto_driver'
    AND     COLUMN_NAME = 'excluded_driver_for_listed_vehicles'
) BEGIN ALTER TABLE edw_core.tauto_driver ADD excluded_driver_for_listed_vehicles varchar(max) END;  