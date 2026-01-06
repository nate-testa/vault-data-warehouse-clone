IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'AccountTransaction'					
AND COLUMN_NAME = 'IndicationStatus'					
) BEGIN ALTER TABLE edw_stage.AccountTransaction ADD IndicationStatus nvarchar(200) END ; 