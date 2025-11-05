select top 100 * from edw_core.tetl_audit where process_nm like '%policy_ivans_pel_feed%' order by etl_audit_sk desc;
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm = 'sp_policy_ivans_pel_feed';
truncate table [edw_integration].[policy_ivans_pel_feed];
EXEC [edw_core].[sp_policy_ivans_pel_feed];
select count(1) from [edw_integration].[policy_ivans_pel_feed];
select top 100 * from [edw_integration].[policy_ivans_pel_feed];

SELECT top 10 * FROM edw_integration.policy_ivans_pel_feed where PolicyNumber_033 = 'EX100262678-02';

SELECT --PV.*
    pv.vehicle_no as id,
    ph.customer_id as insuredId,
    pv.vehicle_type as vehicleType,
    pv.vehicle_vin as vin,
    pv.vehicle_year as modelyear,
    pv.vehicle_make as manufacturer,
    pv.vehicle_model as model  
FROM edw_core.tpel_vehicle as pv
INNER JOIN edw_core.tpolicy_history as ph ON pv.policy_history_sk = ph.policy_history_sk
WHERE pv.policy_no = 'EX100262678-02'
and pv.vehicle_deleted_in = 'Yes'
;