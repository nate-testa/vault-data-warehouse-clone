IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vcarfaxvalue' 
)  
DROP VIEW edw_core.vcarfaxvalue;

GO

CREATE VIEW edw_core.vcarfaxvalue 
AS 
select * from [edw_stage].[tvendor_report_CarfaxValue];