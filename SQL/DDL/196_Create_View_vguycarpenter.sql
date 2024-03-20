IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vguycarpenter' 
)  
DROP VIEW edw_core.vguycarpenter;

GO

CREATE VIEW edw_core.vguycarpenter 
AS 
select * from [edw_stage].[tvendor_report_GuyCarpenter];