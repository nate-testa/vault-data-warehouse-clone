IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'Addr1_063'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD Addr1_063 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'City_064'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD City_064 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'StateProvCd_065'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD StateProvCd_065 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'PostalCode_066'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD PostalCode_066 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'Latitude_067'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD Latitude_067 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'Longitude_068'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD Longitude_068 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'County_069'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD County_069 varchar(255) END


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_ivans_collections_feed'					
AND COLUMN_NAME = 'Country_070'					
) BEGIN ALTER TABLE edw_integration.policy_ivans_collections_feed ADD Country_070 varchar(255) END