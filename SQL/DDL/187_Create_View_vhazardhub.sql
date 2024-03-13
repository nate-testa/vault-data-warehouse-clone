
IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vhazardhub' 
)  
DROP VIEW edw_core.vhazardhub;

GO

CREATE VIEW edw_core.vhazardhub 
AS 
select * from [edw_stage].[tvendor_report_HazardHub];