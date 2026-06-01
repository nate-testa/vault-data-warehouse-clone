IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
      AND COLUMN_NAME = 'NotifierName'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api
    ADD NotifierName Varchar(255);
END;
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
      AND COLUMN_NAME = 'NotifierRelationshipToInsured'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api
    ADD NotifierRelationshipToInsured Varchar(255);
END;
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
      AND COLUMN_NAME = 'NotifierEmail'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api
    ADD NotifierEmail Varchar(255);
END;
 
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
      AND COLUMN_NAME = 'NotifierPhoneNumber'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api
    ADD NotifierPhoneNumber Varchar(255);
END;
