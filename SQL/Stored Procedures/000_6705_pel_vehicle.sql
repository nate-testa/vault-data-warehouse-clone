--tpel_vehicle
select top 100 * from edw_core.tetl_audit where process_nm like 'sp_tpel_vehicle' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm = 'sp_tpel_vehicle';
select COUNT(1) from [edw_core].[tpel_vehicle];
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tpel_vehicle');
-- truncate table [edw_core].[tpel_vehicle];
-- EXEC [edw_core].[sp_tpel_vehicle];


--tquote_pel_vehicle
select top 100 * from edw_core.tetl_audit where process_nm like 'sp_tquote_pel_vehicle%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm like 'sp_tquote_pel_vehicle%';
select COUNT(1) from [edw_core].[tquote_pel_vehicle];
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tquote_pel_vehicle','sp_tquote_pel_vehicle_wip');
-- truncate table [edw_core].[tquote_pel_vehicle];
-- EXEC [edw_core].[sp_tquote_pel_vehicle];
-- EXEC [edw_core].[sp_tquote_pel_vehicle_wip];




SELECT TOP 100 * FROM [edw_temp].[tpel_vehicle_temp1]
WHERE PolicyNumber = 'EX100021288-02'
AND EffectiveDate = '2022-12-02'
AND transaction_seq_no = '11'
AND [Index] = '5'
;

SELECT TOP 100 * FROM [edw_core].[tpel_vehicle]
WHERE policy_no = 'EX100021288-02'
AND effective_dt = '2022-12-02'
AND transaction_seq_no = '11'
AND vehicle_no = '5'
;


SELECT vehicle_deleted_in, count(1) FROM [edw_core].[tpel_vehicle] group by vehicle_deleted_in;

SELECT TOP 100 vehicle_deleted_in, vehicle_unique_id FROM [edw_core].[tpel_vehicle];