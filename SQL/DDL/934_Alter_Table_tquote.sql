IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote'
AND COLUMN_NAME = 'grpel_master_quote_no'
) 
BEGIN 
    ALTER TABLE edw_core.tquote ADD grpel_master_quote_no  varchar(255) NULL
END ; 