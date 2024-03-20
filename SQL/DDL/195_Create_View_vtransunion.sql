IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vtransunion' 
)  
DROP VIEW edw_core.vtransunion;

GO

CREATE VIEW edw_core.vtransunion 
AS 
select * from [edw_stage].[tvendor_report_TransUnion];