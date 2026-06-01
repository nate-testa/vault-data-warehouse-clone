IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
      AND COLUMN_NAME = 'contact_nm'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api
     ADD contact_nm Varchar(255);
END;
 
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
      AND COLUMN_NAME = 'contact_type'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api
    ADD contact_type Varchar(255);
END;
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
      AND COLUMN_NAME = 'contact_person_email'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api
    ADD contact_person_email Varchar(255);
END;
 
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
      AND COLUMN_NAME = 'contact_phone'
)
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api
    ADD contact_phone Varchar(255);
END;