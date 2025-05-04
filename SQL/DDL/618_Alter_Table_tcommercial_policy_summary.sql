IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_policy_summary'					
AND COLUMN_NAME = 'commercial_policy_history_sk'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy_summary ADD commercial_policy_history_sk int NOT NULL END
; 