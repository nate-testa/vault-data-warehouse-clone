IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tcustomer_summary'
    AND     COLUMN_NAME = 'marine_premium_amt'
) BEGIN ALTER TABLE edw_core.tcustomer_summary ADD marine_premium_amt decimal(15, 2) END ;


IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tcustomer_summary'
    AND     COLUMN_NAME = 'group_excess_premium_amt'
) BEGIN ALTER TABLE edw_core.tcustomer_summary ADD group_excess_premium_amt decimal(15, 2) END ;