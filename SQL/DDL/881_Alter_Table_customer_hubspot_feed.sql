IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_integration'					
      AND TABLE_NAME = 'customer_hubspot_feed'					
      AND COLUMN_NAME = 'inforce_net_premium_amt'					
) 
BEGIN 
ALTER TABLE edw_integration.customer_hubspot_feed ADD inforce_net_premium_amt int END ;