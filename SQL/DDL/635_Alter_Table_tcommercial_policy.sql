IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_policy'					
AND COLUMN_NAME = 'prior_policy_no'		
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy ADD prior_policy_no varchar(255) END			 
;   