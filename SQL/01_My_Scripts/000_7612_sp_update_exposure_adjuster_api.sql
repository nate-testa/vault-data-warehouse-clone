select top 100 * from edw_core.tetl_audit where process_nm like '%migration_update_exposure_adjuster_api%' order by etl_audit_sk desc;
select top 100 * from edw_core.tetl_control where process_nm = 'sp_migration_update_exposure_adjuster_api';
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_migration_update_exposure_adjuster_api';
-- truncate table [edw_stage].[migration_update_exposure_adjuster_api];
-- EXEC [edw_core].[sp_migration_update_exposure_adjuster_api];
select count(1) from [edw_stage].[migration_update_exposure_adjuster_api];
select top 100 * from [edw_stage].[migration_update_exposure_adjuster_api];


SELECT u.*
FROM [edw_temp].[migration_update_exposure_adjuster_api_temp1] tmp1
INNER JOIN edw_stage.t_clm_item i ON i.item_id = tmp1.exposure_id
INNER JOIN edw_stage.t_clm_object o     ON o.[object_id] = i.[object_id]
INNER JOIN edw_stage.t_pub_user u     ON u.[USER_ID] = o.owner_id
-- INNER JOIN edw_stage_snapsheet.[users] su     ON su.[name] = u.REAL_NAME
;

select * 
from edw_stage_snapsheet.[users] as su
-- where su.[name] in ('Test ChiefClOfficer','Serena Thompson','Kiera McMeekan')
;


SELECT DISTINCT u.REAL_NAME
FROM edw_stage.t_pub_user u
LEFT JOIN edw_stage_snapsheet.[users] su ON su.[name] = u.REAL_NAME
WHERE su.name IS NULL
;