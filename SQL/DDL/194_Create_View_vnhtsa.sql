IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vnhtsa' 
)  
DROP VIEW edw_core.vnhtsa;

GO

CREATE VIEW edw_core.vnhtsa 
AS 
select * from [edw_stage].[tvendor_report_NHTSA];