IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'group_excess_liability_limit_amt'
)
BEGIN
	exec sp_rename 'edw_core.tgrpel_coverage.group_excess_liability_limit_amt','excess_liability_limit_amt'
END;

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'group_excess_liability_premium_amt '
)
BEGIN
	exec sp_rename 'edw_core.tgrpel_coverage.group_excess_liability_premium_amt ','excess_liability_premium_amt '
END;