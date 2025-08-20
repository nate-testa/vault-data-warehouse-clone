IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tpolicy '                  
AND COLUMN_NAME = 'first_billing_payment_dt'                    
) BEGIN ALTER TABLE edw_core.tpolicy ADD first_billing_payment_dt date NULL END ;