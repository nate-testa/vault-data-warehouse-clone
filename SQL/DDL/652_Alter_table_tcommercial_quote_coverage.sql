IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote_coverage'					
AND COLUMN_NAME = 'retroactive_dt_desc'		
) BEGIN ALTER TABLE edw_commercial.tcommercial_quote_coverage ADD retroactive_dt_desc varchar(255) END			 
;     

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote_coverage'					
AND COLUMN_NAME = 'prior_or_pending_dt_desc'		
) BEGIN ALTER TABLE edw_commercial.tcommercial_quote_coverage ADD prior_or_pending_dt_desc varchar(255) END			 
;    

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote_coverage'					
AND COLUMN_NAME = 'single_round_the_clock_resinstatement_in'		
) BEGIN ALTER TABLE edw_commercial.tcommercial_quote_coverage ADD single_round_the_clock_resinstatement_in varchar(255) END			 
;     
