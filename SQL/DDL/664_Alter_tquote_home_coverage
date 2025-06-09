IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote_home_coverage'                  
AND COLUMN_NAME = 'wildfire_suppression_system'                    
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD wildfire_suppression_system VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote_home_coverage'                  
AND COLUMN_NAME = 'wildfire_decks_balconies_porches_stairs'                    
) BEGIN ALTER TABLE edw_core.tquote_home_coverage ADD wildfire_decks_balconies_porches_stairs VARCHAR(255) NULL END ; 