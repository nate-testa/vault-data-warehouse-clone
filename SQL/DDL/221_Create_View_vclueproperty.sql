IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vclueproperty' 
)  
DROP VIEW edw_core.vclueproperty;

GO

CREATE VIEW edw_core.vclueproperty 
AS 
select * from [edw_stage].[tvendor_report_Clue_Property]; 