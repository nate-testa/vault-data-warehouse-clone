IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'fault_decision'
) BEGIN ALTER TABLE edw_core.tclaim ADD fault_decision varchar(255) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'responsible_party'
) BEGIN ALTER TABLE edw_core.tclaim ADD responsible_party varchar(255) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'at_fault_pct'
) BEGIN ALTER TABLE edw_core.tclaim ADD at_fault_pct varchar(255) END;