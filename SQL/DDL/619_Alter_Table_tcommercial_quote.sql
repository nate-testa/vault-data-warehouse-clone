IF EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote'					
AND COLUMN_NAME = 'policy_sk'					
) BEGIN EXEC sp_RENAME 'edw_commercial.tcommercial_quote.policy_sk', 'commercial_policy_sk', 'column' END
; 

IF EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote'					
AND COLUMN_NAME = 'prior_term_policy_sk'					
) BEGIN EXEC sp_RENAME 'edw_commercial.tcommercial_quote.prior_term_policy_sk', 'prior_term_commercial_policy_sk', 'column' END
; 
