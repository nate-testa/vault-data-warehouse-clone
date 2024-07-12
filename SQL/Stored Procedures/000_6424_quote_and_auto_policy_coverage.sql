-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tauto_policy_coverage';
-- select count(1) from [edw_core].[tauto_policy_coverage];
-- truncate table [edw_core].[tauto_policy_coverage];
-- EXEC [edw_core].[sp_tauto_policy_coverage];


-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_auto_policy_coverage';
-- select COUNT(1) from [edw_core].[tquote_auto_policy_coverage];
-- truncate table [edw_core].[tquote_auto_policy_coverage];
-- EXEC [edw_core].[sp_tquote_auto_policy_coverage];


-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_auto_policy_coverage_wip';
-- select COUNT(1) from [edw_core].[tquote_auto_policy_coverage];
-- truncate table [edw_core].[tquote_auto_policy_coverage];
-- EXEC [edw_core].[sp_tquote_auto_policy_coverage_wip];




--check data
select count(1) , count(sdip_points), count(sdip_points_no)
from [edw_core].[tauto_policy_coverage]
;

select count(1) , count(sdip_points), count(sdip_points_no)
from [edw_core].[tquote_auto_policy_coverage]
;

select distinct sdip_points
from [edw_core].[tauto_policy_coverage]
;