IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vaoncatstore' 
)  
DROP VIEW edw_core.vaoncatstore;

GO

CREATE VIEW edw_core.vaoncatstore 
AS 
select * from [edw_stage].[tvendor_report_AonCatStore]; 