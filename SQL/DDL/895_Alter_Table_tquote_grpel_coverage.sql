IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_coverage'
AND COLUMN_NAME = 'group_excess_liability_limit_amt'
)
BEGIN
	exec sp_rename 'edw_core.tquote_grpel_coverage.group_excess_liability_limit_amt','excess_liability_limit_amt'
END;

