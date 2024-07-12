IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vmvr' 
)  
DROP VIEW edw_core.vmvr;

GO

CREATE VIEW edw_core.vmvr 
AS 
select * from [edw_stage].[tvendor_report_MVR];