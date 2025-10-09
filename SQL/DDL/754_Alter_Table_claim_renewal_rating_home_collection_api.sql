IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
        AND COLUMN_NAME = 'LargeLoss')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api ADD LargeLoss VARCHAR(255) NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
        AND COLUMN_NAME = 'LossDescription2')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api ADD IncidentDescription2 NVARCHAR(MAX) NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'
        AND COLUMN_NAME = 'TotalIncurred')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api ADD TotalIncurred DECIMAL(15,2) NULL;
END;