IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'accepted_renewal_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD accepted_renewal_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'not_accepted_renewal_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD not_accepted_renewal_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'outstanding_renewal_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD outstanding_renewal_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'offered_quote_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD offered_quote_ct int END ;  

 




