IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = '2026_homeowner_premium_goal_amt'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD [2026_homeowner_premium_goal_amt] decimal(15,2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = 'ytd_new_business_homeowner_premium_amt'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD ytd_new_business_homeowner_premium_amt decimal(15,2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = '2026_homeowner_goal_progress_pc'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD [2026_homeowner_goal_progress_pc] decimal(15,2) NULL;
END;