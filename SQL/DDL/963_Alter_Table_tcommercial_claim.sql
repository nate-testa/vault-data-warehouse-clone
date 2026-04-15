IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim'
      AND COLUMN_NAME = 'last_update_ts'
)
BEGIN
    exec sp_rename 'edw_commercial.tcommercial_claim.last_update_ts','claim_last_updated_ts';
END;