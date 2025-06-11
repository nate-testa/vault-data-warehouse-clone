IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vmajescocashactivity' 
)  
DROP VIEW edw_core.vmajescocashactivity;

GO

CREATE VIEW edw_core.vmajescocashactivity
AS 
select * from [edw_stage].[stage_majesco_cash_activity];
