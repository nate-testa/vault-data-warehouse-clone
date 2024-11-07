IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vticoplacecodes' 
)  
DROP VIEW edw_core.vticoplacecodes;

GO

CREATE VIEW edw_core.vticoplacecodes 
AS 
SELECT
*
FROM edw_stage.tico_place_code
;