IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vmajescoduedateaging' 
)  
DROP VIEW edw_core.vmajescoduedateaging;

GO

CREATE VIEW edw_core.vmajescoduedateaging
AS 
select * from [edw_stage].[stage_majesco_due_date_aging];

