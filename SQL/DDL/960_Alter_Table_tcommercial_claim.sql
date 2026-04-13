IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim'
      AND COLUMN_NAME = 'loss_location_desc'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim ADD loss_location_desc NVARCHAR(max);
END;
 
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim'
      AND COLUMN_NAME = 'large_loss_in'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim ADD large_loss_in VARCHAR(255);
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim'
      AND COLUMN_NAME = 'closed_reason_desc'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim ADD closed_reason_desc VARCHAR(255);
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim'
      AND COLUMN_NAME = 'last_update_ts'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim ADD last_update_ts DATETIME;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_commercial'
      AND TABLE_NAME = 'tcommercial_claim_feature'
      AND COLUMN_NAME = 'closed_reason_desc'
)
BEGIN
    ALTER TABLE edw_commercial.tcommercial_claim_feature ADD closed_reason_desc VARCHAR(255) ;
END;


 