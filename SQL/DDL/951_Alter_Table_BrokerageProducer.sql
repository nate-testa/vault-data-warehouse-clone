IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'BrokerageProducer'
      AND COLUMN_NAME = 'ExternalSourceId'
)
BEGIN
    ALTER TABLE edw_stage.BrokerageProducer ADD ExternalSourceId NVARCHAR(256) NULL;
END;
 
