IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = 'homeowner_2026_premium_goal_amt'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD homeowner_2026_premium_goal_amt decimal(15,2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = 'homeowner_2026_premium_actual_amt'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD homeowner_2026_premium_actual_amt decimal(15,2) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'broker_hubspot_feed'
      AND COLUMN_NAME = 'homeowner_2026_goal_progress_pc'
)
BEGIN
    ALTER TABLE edw_integration.broker_hubspot_feed ADD homeowner_2026_goal_progress_pc decimal(10,2) NULL;
END;