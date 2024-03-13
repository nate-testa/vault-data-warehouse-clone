IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'visoproperty' 
)  
DROP VIEW edw_core.visoproperty;

GO

CREATE VIEW edw_core.visoproperty 
AS 
select * from [edw_stage].[tvendor_report_IsoProperty];