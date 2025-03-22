IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vredzone' 
)  
DROP VIEW edw_core.vredzone;

GO

CREATE VIEW edw_core.vredzone 
AS 
select * from [edw_stage].[tvendor_report_redzone];