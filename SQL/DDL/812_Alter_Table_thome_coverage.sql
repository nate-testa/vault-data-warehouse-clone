IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'thome_coverage'					
AND COLUMN_NAME = 'num_of_family_units_in_structure'					
) BEGIN ALTER TABLE edw_core.thome_coverage ADD num_of_family_units_in_structure varchar(255) END ; 
