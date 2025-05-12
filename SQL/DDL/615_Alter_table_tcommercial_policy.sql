IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA = 'edw_commercial'
AND TABLE_NAME = 'tcommercial_policy'
AND COLUMN_NAME = 'cancellation_effective_dt'
) BEGIN ALTER TABLE edw_commercial.tcommercial_policy ADD cancellation_effective_dt DATE END
;
