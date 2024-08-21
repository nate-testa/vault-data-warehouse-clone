IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vlc360' 
)  
DROP VIEW edw_core.vlc360;

GO

CREATE VIEW edw_core.vlc360 
AS 
select * from [edw_stage].[tvendor_report_LC360];