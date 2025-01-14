IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'broker_hubspot_feed'
    AND     COLUMN_NAME = 'ytd_nb_yacht_premium_amt'
) BEGIN ALTER TABLE edw_integration.broker_hubspot_feed ADD ytd_nb_yacht_premium_amt decimal(15,2) null END; 