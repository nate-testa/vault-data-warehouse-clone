IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tgrpel_coverage'
      AND CONSTRAINT_NAME = 'pk_tgrpel_coverage'
)
BEGIN
    ALTER TABLE edw_core.tgrpel_coverage
    DROP CONSTRAINT pk_tgrpel_coverage;
END;

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'group_umbrella_coverage_sk'
)
BEGIN
	exec sp_rename 'edw_core.tgrpel_coverage.group_umbrella_coverage_sk','grpel_coverage_sk'
END;


IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tgrpel_coverage'
AND COLUMN_NAME = 'group_umbrella_policy_no'
)
BEGIN
	exec sp_rename 'edw_core.tgrpel_coverage.group_umbrella_policy_no','grpel_policy_no'
END;

-- Recreate PK only if it does not exist
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tgrpel_coverage'
      AND CONSTRAINT_NAME = 'pk_tgrpel_coverage'
)
BEGIN
    ALTER TABLE edw_core.tgrpel_coverage
        ADD CONSTRAINT pk_tgrpel_coverage 
        PRIMARY KEY (grpel_coverage_sk);
END;
