IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpolicy'
      AND COLUMN_NAME = 'risk_address_county_nm'
)
BEGIN
    ALTER TABLE edw_core.tpolicy ADD risk_address_county_nm Varchar(255);
END;
 