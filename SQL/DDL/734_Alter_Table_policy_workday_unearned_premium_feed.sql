IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'scheduled_limit_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD scheduled_limit_amt varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'blanket_limit_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD blanket_limit_amt varchar(255) END