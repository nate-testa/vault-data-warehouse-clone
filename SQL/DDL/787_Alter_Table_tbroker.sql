IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tbroker'
AND COLUMN_NAME = 'allow_communication_to_customer_in'
) 
BEGIN 
    ALTER TABLE edw_core.tbroker ADD allow_communication_to_customer_in VARCHAR(255) NULL 
END