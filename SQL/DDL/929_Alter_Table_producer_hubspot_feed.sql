IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'producer_hubspot_feed'
AND COLUMN_NAME = 'customer_business_type'
) 
BEGIN 
	ALTER TABLE edw_integration.producer_hubspot_feed ADD customer_business_type varchar(255) NULL
END;   

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'producer_hubspot_feed'
AND COLUMN_NAME = 'ytd_submission_ct'
) 
BEGIN 
	ALTER TABLE edw_integration.producer_hubspot_feed ADD ytd_submission_ct int NULL default 0
END;  
 
