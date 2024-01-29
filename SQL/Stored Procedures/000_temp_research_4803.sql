select * from edw_core.tpolicy_history where policy_no =  'AU100004762-01';
select DISTINCT policy_no, vehicle_vin from edw_core.tauto_vehicle where trim(vehicle_type) = '/';--299


select * from edw_core.tauto_vehicle where policy_no =  'AU100012285';