IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'visovehicle' 
)  
DROP VIEW edw_core.visovehicle;

GO

CREATE VIEW edw_core.visovehicle 
AS 
select * from [edw_stage].[tvendor_report_IsoVehicle];