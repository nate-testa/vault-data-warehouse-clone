IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tedw_table_detail'					
AND COLUMN_NAME = 'schema_nm'					
) BEGIN ALTER TABLE edw_core.tedw_table_detail ADD schema_nm varchar(255) END