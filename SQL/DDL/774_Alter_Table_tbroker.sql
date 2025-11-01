IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tbroker'
AND COLUMN_NAME = 'affiliation_in'
) 
BEGIN 
    ALTER TABLE edw_core.tbroker ADD affiliation_in VARCHAR(255) NULL
END ;

IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tbroker'
AND COLUMN_NAME = 'broker_affiliation_nm'
) 
BEGIN 
    ALTER TABLE edw_core.tbroker ADD broker_affiliation_nm VARCHAR(255) NULL
END ;

