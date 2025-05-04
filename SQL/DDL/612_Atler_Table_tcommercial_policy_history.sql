IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_policy_history'					
AND COLUMN_NAME = 'transaction_issue_ts'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy_history ADD transaction_issue_ts datetime END
;


