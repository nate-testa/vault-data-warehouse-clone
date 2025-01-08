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
select 
    policynumber
    ,effectivedate
    ,dateordered
    ,dateTimeRecieved
    ,dateTimeCompleted
    ,TransactionStatus
    ,IsReportFromCache
    ,source
    ,reporttype
    ,[Answers - Construction Type]
    ,[Answers - CoverageAOut]
    ,[Answers - Fire Protection]
    ,[Answers - Fire Sprinkler System Present]
    ,[Answers - Fire Station Connected Alarm]
    ,[Answers - LossPrevention_ConfirmedCredits]
    ,[Answers - Occupancy]
    ,[Answers - Roof Covering]
    ,[Answers - Roof Shape]
    ,[Answers - Roof Year]
    ,[Answers - RoofAge]
    ,[Answers - Year of Construction]
    ,[Answers - Year replaced - Roof]
    ,[Answers - Year updated - Electrical]
    ,[Answers - Year updated - Heating and A/C]
    ,[Answers - Year updated - Plumbing]
    ,[Endorsement Revised - Revised Coverage A]
from [edw_stage].[tvendor_report_LC360]
;


