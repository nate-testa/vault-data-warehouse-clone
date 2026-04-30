IF NOT EXISTS (                 
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                 
WHERE TABLE_SCHEMA='edw_stage'                   
AND TABLE_NAME = 'AccountPayment'                 
AND COLUMN_NAME = 'TransactionDate'                 
) BEGIN ALTER TABLE edw_stage.AccountPayment ADD TransactionDate datetime2(7) END ; 