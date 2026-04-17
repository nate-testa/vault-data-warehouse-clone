IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'AccountPayment'
      AND COLUMN_NAME = 'LineItemCategory'
)
BEGIN
    ALTER TABLE edw_stage.AccountPayment ADD LineItemCategory NVARCHAR(200) NULL;
END;
 
