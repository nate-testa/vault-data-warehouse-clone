IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vlivevox' 
)  
DROP VIEW edw_core.vlivevox;

GO

CREATE VIEW edw_core.vlivevox 
AS 
SELECT
*
FROM edw_stage.stage_livevox
;