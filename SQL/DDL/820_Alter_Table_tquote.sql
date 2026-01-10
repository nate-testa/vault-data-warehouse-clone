IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote'					
AND COLUMN_NAME = 'non_binding_indication_offered_in'					
) BEGIN ALTER TABLE edw_core.tquote ADD non_binding_indication_offered_in Varchar(255) END ; 