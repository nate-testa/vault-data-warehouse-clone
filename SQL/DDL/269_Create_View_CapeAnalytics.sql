IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vcapeanalytics' 
)  
DROP VIEW edw_core.vcapeanalytics;

GO

CREATE VIEW edw_core.vcapeanalytics 
AS 
select * from [edw_stage].[tvendor_report_CapeAnalytics];