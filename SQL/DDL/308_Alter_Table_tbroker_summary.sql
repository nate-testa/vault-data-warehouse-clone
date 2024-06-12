IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'prior_mtd_gross_net_premium_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_gross_net_premium_amt decimal(15,2) null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'mtd_gross_net_premium_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD mtd_gross_net_premium_amt decimal(15,2) null END;  