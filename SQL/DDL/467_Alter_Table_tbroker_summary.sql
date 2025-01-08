IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'policy_renewal_accepted_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD policy_renewal_accepted_ct int END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tbroker_summary'
    AND     COLUMN_NAME = 'ytd_policy_renewal_accepted_ct'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD ytd_policy_renewal_accepted_ct int END;

alter table edw_core.tbroker_summary
alter column policy_renewal_offered_expiring_premium_amt decimal(10,2);

alter table edw_core.tbroker_summary
alter column policy_renewal_offered_premiumm_amt decimal(10,2); 
