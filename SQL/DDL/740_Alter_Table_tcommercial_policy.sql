IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_policy'					
AND COLUMN_NAME = 'policy_inforce_in'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy ADD policy_inforce_in varchar(255) END