IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'do_limit_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD do_limit_amt varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'employment_practices_liability_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD employment_practices_liability_amt varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'pel_limit_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD pel_limit_amt varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'uninsured_underinsured_liability_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD uninsured_underinsured_liability_amt varchar(255) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_workday_unearned_premium_feed'					
AND COLUMN_NAME = 'uninsured_underinsured_motorist_liability_amt'					
) BEGIN ALTER TABLE edw_integration.policy_workday_unearned_premium_feed ADD uninsured_underinsured_motorist_liability_amt varchar(255) END