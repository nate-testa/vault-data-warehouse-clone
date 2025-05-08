
IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tquote'                  
AND COLUMN_NAME = 'forcast_quote_in'                    
)
BEGIN
ALTER table edw_core.tquote ADD forcast_quote_in varchar(255)
END;