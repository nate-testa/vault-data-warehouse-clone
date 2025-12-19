IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'transaction_effective_date'					
) 
BEGIN 
    ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD transaction_effective_date DATE NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'transaction_ts'					
) 
BEGIN 
    ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD transaction_ts DATE NULL
END ;
