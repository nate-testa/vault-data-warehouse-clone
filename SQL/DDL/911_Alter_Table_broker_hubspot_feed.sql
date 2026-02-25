IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'broker_hubspot_feed'
AND COLUMN_NAME = 'ytd_inforce_ct'
) 
BEGIN 
	ALTER TABLE edw_integration.broker_hubspot_feed ADD ytd_inforce_ct INT NULL
END; 

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'broker_hubspot_feed'
AND COLUMN_NAME = 'ytd_inforce_premium_amt'
) 
BEGIN 
	ALTER TABLE edw_integration.broker_hubspot_feed ADD ytd_inforce_premium_amt DECIMAL(15,2) NULL
END;

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'broker_hubspot_feed'
AND COLUMN_NAME = 'lifetime_inforce_ct '
) 
BEGIN 
	ALTER TABLE edw_integration.broker_hubspot_feed ADD lifetime_inforce_ct INT NULL
END; 

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'broker_hubspot_feed'
AND COLUMN_NAME = 'lifetime_inforce_premium_amt '
) 
BEGIN 
	ALTER TABLE edw_integration.broker_hubspot_feed ADD lifetime_inforce_premium_amt DECIMAL(15,2) NULL
END; 