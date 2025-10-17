IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
        AND COLUMN_NAME = 'LargeLoss')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD LargeLoss VARCHAR(255) NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
        AND COLUMN_NAME = 'IncidentDescription2')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD IncidentDescription2 NVARCHAR(MAX) NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'edw_integration'
        AND TABLE_NAME = 'claim_renewal_rating_auto_pel_api'
        AND COLUMN_NAME = 'TotalIncurred')
BEGIN
    ALTER TABLE edw_integration.claim_renewal_rating_auto_pel_api ADD TotalIncurred DECIMAL(15,2) NULL;
END;