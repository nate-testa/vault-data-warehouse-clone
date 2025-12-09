IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'renewal_accepted_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_accepted_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'renewal_not_accepted_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_not_accepted_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'renewal_outstanding_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_outstanding_ct int END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'trenewal_summary'					
AND COLUMN_NAME = 'quote_offered_ct'					
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD quote_offered_ct int END ; 

 




