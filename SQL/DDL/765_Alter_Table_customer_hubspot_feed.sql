IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'customer_hubspot_feed'					
AND COLUMN_NAME = 'uw_company_nm'					
) BEGIN ALTER TABLE edw_integration.customer_hubspot_feed ADD uw_company_nm varchar(255) END ;