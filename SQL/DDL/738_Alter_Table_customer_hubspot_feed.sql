IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'occupancy_type'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD occupancy_type varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'effective_dt'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD effective_dt date END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'expiration_dt'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD expiration_dt date END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'policy_inforce_in'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD policy_inforce_in varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'per_claim_policy_limit_amt'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD per_claim_policy_limit_amt int END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'per_claim_attachment_amt'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD per_claim_attachment_amt int END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'per_claim_retention_amt'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD per_claim_retention_amt int END