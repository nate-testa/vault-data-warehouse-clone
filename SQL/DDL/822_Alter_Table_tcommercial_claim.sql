IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_commercial'
AND TABLE_NAME = 'tcommercial_claim'
AND COLUMN_NAME = 'salvage_recover_expense_reserve_amt'
) 
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim DROP COLUMN salvage_recover_expense_reserve_amt
END ; 