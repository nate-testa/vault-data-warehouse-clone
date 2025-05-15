
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_renewal_summary'					
AND COLUMN_NAME = 'renewal_written_premium_amt'		
) BEGIN ALTER TABLE edw_commercial.tcommercial_renewal_summary ADD renewal_written_premium_amt [decimal](15,2) END			 
;     
IF EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_renewal_summary'					
AND COLUMN_NAME = 'renewal_quote_attachement_amt'	 
) BEGIN EXEC sp_RENAME 'edw_commercial.tcommercial_renewal_summary.renewal_quote_attachement_amt', 'renewal_quote_attachment_amt', 'column' END		 
;     

