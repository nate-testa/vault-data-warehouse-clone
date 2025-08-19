IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'policy_current_carrier_auto_np01_feed'
AND COLUMN_NAME = 'reporting_period_begin_dt '
) 
BEGIN 
    ALTER TABLE edw_integration.policy_current_carrier_auto_np01_feed ADD reporting_period_begin_dt date not null
END

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'policy_current_carrier_auto_np01_feed'
AND COLUMN_NAME = 'reporting_period_end_dt'
)
BEGIN
    ALTER TABLE edw_integration.policy_current_carrier_auto_np01_feed ADD reporting_period_end_dt date  not null
END
