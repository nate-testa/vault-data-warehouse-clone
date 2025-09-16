IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote'                  
AND COLUMN_NAME = 'renewal_quote_in'                    
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD renewal_quote_in VARCHAR(255) NULL
END ;

IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote'                  
AND COLUMN_NAME = 'renewal_quote_review_start_dt'                    
)
BEGIN
        ALTER TABLE edw_core.tquote ADD renewal_quote_review_start_dt date NULL
END ;