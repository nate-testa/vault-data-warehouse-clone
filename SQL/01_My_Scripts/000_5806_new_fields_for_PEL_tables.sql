-- select count(1) from [edw_core].[tauto_vehicle_coverage];
-- select * from [edw_core].[tauto_vehicle_coverage];
-- update edw_core.tetl_control set last_source_extract_ts = '2023-06-01 00:00:00' where process_nm in ('sp_tauto_vehicle_coverage');
-- truncate table [edw_core].[tauto_vehicle_coverage];
-- EXEC [edw_core].[sp_tauto_vehicle_coverage];




--pel tables
--**********************
--****SEARCH COLUMNS****
--**********************
;
select distinct acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group]
-- select *
from edw_stage.AccountTransactionVersionObject as acctvo
inner join edw_stage.AccountTransactionVersionObjectField as acctvof
on acctvof.VersionObjectId = acctvo.Id
where 1=1``
and acctvof.field like '%quare%oo%'
-- and acctvo.[Group] in ('Location Details')
-- and acctvof.field in ('SquareFootage','NumberofAthleticStructures','ShortTermRental','LongTermRental')
;

select top 10 * from edw_stage.AccountTransactionVersionObjectField;