IF NOT EXISTS (                 
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                 
WHERE TABLE_SCHEMA='edw_integration'                   
AND TABLE_NAME = 'billing_grpel_cash_activity_feed'                 
AND COLUMN_NAME = 'transaction_date'                 
) BEGIN ALTER TABLE edw_integration.billing_grpel_cash_activity_feed ADD transaction_date date END ; 