IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'                  
AND COLUMN_NAME = 'LitigationIn'                    
) BEGIN ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api ADD LitigationIn VARCHAR(255) NULL END ; 

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_integration'                
AND TABLE_NAME = 'claim_renewal_rating_home_collection_api'                  
AND COLUMN_NAME = 'LitigationCompleteIn'                    
) BEGIN ALTER TABLE edw_integration.claim_renewal_rating_home_collection_api ADD LitigationCompleteIn VARCHAR(255) NULL END ; 
