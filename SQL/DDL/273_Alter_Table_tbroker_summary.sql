IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'policy_renewal_offered_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD policy_renewal_offered_ct int null END;  

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'policy_renewal_offered_premiumm_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD policy_renewal_offered_premiumm_amt int null END;  