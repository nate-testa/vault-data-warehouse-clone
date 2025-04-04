IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_policy_tower'					
AND COLUMN_NAME = 'tower_no'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy_tower ADD tower_no int END
;
