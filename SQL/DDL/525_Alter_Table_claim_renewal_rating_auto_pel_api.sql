IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
    AND     COLUMN_NAME = 'FaultDecision'
) BEGIN ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD FaultDecision VARCHAR(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
    AND     COLUMN_NAME = 'ResponsibleParty'
) BEGIN ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD ResponsibleParty VARCHAR(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
    AND     COLUMN_NAME = 'AtFaultPercent'
) BEGIN ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD AtFaultPercent VARCHAR(255) END; 