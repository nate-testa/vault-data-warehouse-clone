IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vissterritory' 
)  
DROP VIEW edw_core.vissterritory;

GO

CREATE VIEW edw_core.vissterritory 
AS 
SELECT 
	state_cd,
	zip_cd,
	territory,
	create_ts
FROM edw_stage.stage_iss_territory
