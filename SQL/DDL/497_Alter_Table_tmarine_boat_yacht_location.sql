IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tmarine_boat_yacht_location'
    AND     COLUMN_NAME = 'longitude'
) BEGIN ALTER TABLE edw_core.tmarine_boat_yacht_location DROP COLUMN longitude END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tmarine_boat_yacht_location'
    AND     COLUMN_NAME = 'latitude'
) BEGIN ALTER TABLE edw_core.tmarine_boat_yacht_location DROP COLUMN latitude END;