-- 1/5/2026 Sandeep Gundreddy : Created view to consolidate vlc360 data from multiple staging tables
CREATE OR ALTER VIEW [edw_core].[vlc360] 
AS 
select 
    a.policynumber
    ,a.effectivedate
    ,a.dateordered
    ,a.dateTimeRecieved
    ,a.dateTimeCompleted
    ,a.TransactionStatus
    ,a.IsReportFromCache
    ,a.source
    ,a.reporttype
    ,a.[Answers - Construction Type]
    ,a.[Answers - CoverageAOut]
    ,a.[Answers - Fire Protection]
    ,a.[Answers - Fire Sprinkler System Present]
    ,a.[Answers - Fire Station Connected Alarm]
    ,a.[Answers - LossPrevention_ConfirmedCredits]
    ,a.[Answers - Occupancy]
    ,a.[Answers - Roof Covering]
    ,a.[Answers - Roof Shape]
    ,a.[Answers - Roof Year]
    ,a.[Answers - RoofAge]
    ,a.[Answers - Year of Construction]
    ,a.[Answers - Year replaced - Roof]
    ,a.[Answers - Year updated - Electrical]
    ,a.[Answers - Year updated - Heating and A/C]
    ,a.[Answers - Year updated - Plumbing]
    ,a.[Endorsement Revised - Revised Coverage A]
    ,COALESCE(
    c.[Summary - Inspection Number],
    CASE 
        WHEN TRY_CAST(a.[Inspection - Inspection Number] AS INT) IS NOT NULL
            THEN a.[Inspection - Inspection Number]
    END
	) AS InspectionNumber,
	c.[Summary - Request Date] AS RequestDate, 
	c.[Summary - Requested By] AS RequestedBy   
from [edw_stage].[tvendor_report_LC360] a 
left join [edw_stage].[tvendor_report_LC360_6] c 
	on a.policynumber  = c.policynumber 
	and a.effectivedate = c.effectivedate  
	and a.dateordered  = c.dateordered  
	and a.dateTimeRecieved  = c.dateTimeRecieved  
	and a.dateTimeCompleted  = c.dateTimeCompleted  
;
GO