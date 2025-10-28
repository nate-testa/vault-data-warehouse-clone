IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tbroker'
AND COLUMN_NAME = 'is_affiliation_in'
) 
BEGIN 
    ALTER TABLE edw_core.tbroker ADD is_affiliation_in VARCHAR(255) NULL
END ;

IF NOT EXISTS (                
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tbroker'
AND COLUMN_NAME = 'affiliation_agency_nm'
) 
BEGIN 
    ALTER TABLE edw_core.tbroker ADD affiliation_agency_nm VARCHAR(255) NULL
END ;