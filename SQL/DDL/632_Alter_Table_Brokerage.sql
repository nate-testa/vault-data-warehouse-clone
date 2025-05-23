IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'Brokerage'					
AND COLUMN_NAME = 'ServicingTeamId'					
) BEGIN ALTER TABLE edw_stage.Brokerage ADD ServicingTeamId uniqueidentifier NULL END ; 