IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vticoplacecode' 
)  
DROP VIEW edw_core.vticoplacecode;

GO

CREATE VIEW edw_core.vticoplacecode 
AS 
SELECT
*
FROM edw_stage.stage_tico_place_code
;