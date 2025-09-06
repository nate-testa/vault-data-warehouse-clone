IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_transaction'					
AND COLUMN_NAME = 'ncrb_premium_amt'					
) BEGIN ALTER TABLE edw_core.tquote_transaction ADD ncrb_premium_amt decimal(16,4) END

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_transaction'					
AND COLUMN_NAME = 'ncrb_annual_premium_amt'					
) BEGIN ALTER TABLE edw_core.tquote_transaction ADD ncrb_annual_premium_amt decimal(16,4) END