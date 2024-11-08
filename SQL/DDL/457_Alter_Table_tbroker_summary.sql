IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_expiring_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_expiring_ct int END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_ct int END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_offered_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_offered_ct int END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_offered_over_50k_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_offered_over_50k_ct int END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_offered_premiumm_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_offered_premiumm_amt decimal(10,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_offered_expiring_premium_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_offered_expiring_premium_amt decimal(10,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_expiring_premium_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_expiring_premium_amt decimal(10,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_premium_amt'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_premium_amt decimal(10,2) END;