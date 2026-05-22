IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'commercial_claim_renewal_rating_api'
AND COLUMN_NAME = 'FactOfLoss'
)
BEGIN
    ALTER TABLE edw_integration.commercial_claim_renewal_rating_api ALTER COLUMN [FactOfLoss] NVARCHAR(max) ;
END ;

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'commercial_claim_renewal_rating_api'
AND COLUMN_NAME = 'AdditionalFactOfLoss'
)
BEGIN
    ALTER TABLE edw_integration.commercial_claim_renewal_rating_api ALTER COLUMN [AdditionalFactOfLoss] NVARCHAR(max) ;
END ;
