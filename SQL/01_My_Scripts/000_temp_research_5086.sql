SELECT COUNT(1) FROM [edw_integration].[policy_hsb_cyber_feed] AS hcp;
SELECT COUNT(1) FROM [edw_integration].[policy_hsb_hsp_feed] AS hsb;
SELECT COUNT(1) FROM [edw_integration].[policy_hsb_slc_feed] AS slc;

SELECT * FROM [edw_integration].[policy_hsb_cyber_feed] AS hcp;
SELECT * FROM [edw_integration].[policy_hsb_hsp_feed] AS hsb;
SELECT distinct occupancy FROM [edw_integration].[policy_hsb_slc_feed] AS slc;

SELECT distinct [residence_type] AS 'Residence_Type'
-- SELECT distinct SUBSTRING(policy_no,1,2)
FROM [edw_integration].[policy_hsb_slc_feed]
;

select distinct 
residence_type,
occupancy_type,
CASE 
    WHEN residence_type = 'Tenant' THEN 'Tenant'
    WHEN occupancy_type IN ('Primary','Rented to Others','Partially Rented to Others') THEN 'Owner'
    WHEN occupancy_type = 'Vacant' THEN 'Vacant'
    WHEN occupancy_type LIKE 'Seasonal%' THEN 'Seasonal'
END AS occupancy
from edw_core.thome_coverage
order by 1,2
;


select 
residence_type,
count(1) as row_count
from edw_core.thome_coverage
group by residence_type