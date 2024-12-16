IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_payment'
    AND     COLUMN_NAME = 'cost_category'
) BEGIN ALTER TABLE edw_core.tclaim_payment ADD cost_category varchar(255) END; 