-- 1/12/2026 Dinesh Bobbili : Updated view logic to select all columns from main table
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
    c.lc360_summ_insp_num,
    CASE 
        WHEN TRY_CAST(a.lc360_insp_insp_num AS INT) IS NOT NULL
            THEN a.lc360_insp_insp_num
    END
	) AS InspectionNumber,
	c.lc360_sum_req_date AS RequestDate, 
	c.lc360_sum_req_by AS RequestedBy   
from [edw_stage].[tvendor_report_LC360] a 
;
GO