IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy_history'
      AND COLUMN_NAME = 'grpel_policy_credit_in'
)
BEGIN
    ALTER TABLE edw_core.tpolicy_history ADD grpel_policy_credit_in Varchar(255);
END;