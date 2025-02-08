
IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'source_of_fire'
) BEGIN ALTER TABLE edw_core.tclaim ADD source_of_fire varchar(255) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'source_of_water'
) BEGIN ALTER TABLE edw_core.tclaim ADD source_of_water varchar(255) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'first_party_driver_nm'
) BEGIN ALTER TABLE edw_core.tclaim ADD first_party_driver_nm varchar(255) END;

