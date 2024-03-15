IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vcarfaxmileage' 
)  
DROP VIEW edw_core.vcarfaxmileage;

GO

CREATE VIEW edw_core.vcarfaxmileage 
AS 
select * from [edw_stage].[tvendor_report_CarfaxMileage];