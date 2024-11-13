IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_cost_category'
    AND     COLUMN_NAME = 'source_system_sk'
) BEGIN ALTER TABLE edw_core.tclaim_cost_category ADD source_system_sk int END; 