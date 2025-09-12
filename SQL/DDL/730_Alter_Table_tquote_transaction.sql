IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_transaction'
AND COLUMN_NAME = 'ncrb_premium_amt'
)
BEGIN
	exec sp_rename 'edw_core.tquote_transaction.ncrb_premium_amt','state_premium_amt'
END

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_transaction'
AND COLUMN_NAME = 'ncrb_annual_premium_amt'
)
BEGIN
	exec sp_rename 'edw_core.tquote_transaction.ncrb_annual_premium_amt','state_annual_premium_amt'
END