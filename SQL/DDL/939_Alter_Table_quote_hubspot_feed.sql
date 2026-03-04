IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'quote_hubspot_feed'
      AND COLUMN_NAME = 'quote_no_original'
)
BEGIN
    ALTER TABLE edw_integration.quote_hubspot_feed ADD quote_no_original VARCHAR(256) NULL;
END;
 