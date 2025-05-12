IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tpolicy'
    AND     COLUMN_NAME = 'lifetime_claim_ct'
) BEGIN ALTER TABLE edw_core.tpolicy ADD lifetime_claim_ct int END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tpolicy'
    AND     COLUMN_NAME = 'lifetime_loss_incurred_amt'
) BEGIN ALTER TABLE edw_core.tpolicy ADD lifetime_loss_incurred_amt decimal(15,2) END;  