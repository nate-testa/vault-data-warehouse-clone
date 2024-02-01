select * from edw_core.tpolicy_history where policy_no =  'AU100004762-01';
select * from edw_core.tauto_vehicle where trim(vehicle_type) = '/';--299


select source_system_sk, count(1) as row_count
from edw_core.tauto_vehicle 
where trim(vehicle_type) = '/' 
group by source_system_sk;

SELECT * FROM edw_core.tauto_vehicle WHERE policy_no = 'AU100012285';

-- TRUNCATE TABLE [edw_temp].[av2_auto_vehicle];
select * from [edw_temp].[av2_auto_vehicle] where policyimageidentifierid = '61a7a931fbfe370156590e02';


SELECT * FROM edw_stage.AccountTransactionVersion WHERE ExternalSourceId = '61a7a931fbfe370156590e02';
SELECT * FROM edw_stage.AccountTransactionVersionObject WHERE ExternalSourceId = '629d403fa5e99b1f5341df22'; WHERE AccountTransactionVersionId = 260383 AND ObjectType = 'Vehicle' and ExternalSourceId = '629d403fa5e99b1f5341df22';
SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
WHERE Field = 'VehicleType'
AND VersionObjectId in (
    2684678
    );


--Cruce final
SELECT av.policy_no, av.effective_dt, acctvo.[UniqueId] as vehicle_unique_id, av.policyimageidentifierid, av.PolicyObjectIdentifierId, acctvof.VersionObjectId, acctvof.[Value] AS metal_vehicle_type, av.vehicle_type AS AV2_vehicle_type
-- INTO [edw_temp].[metal_auto_vehicle_type]
FROM [edw_temp].[av2_auto_vehicle] av
INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.ExternalSourceId = av.policyimageidentifierid AND acctv.PolicyNumber = av.policy_no
INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id AND acctvo.ExternalSourceId = av.PolicyObjectIdentifierId
INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 1=1
    AND acctvo.ObjectType = 'Vehicle'
    AND acctvof.Field = 'VehicleType'
;

SELECT * 
FROM edw_core.tauto_vehicle AS av
LEFT JOIN [edw_temp].[metal_auto_vehicle_type] AS mav ON mav.policy_no = av.policy_no AND mav.effective_dt = av.effective_dt AND mav.vehicle_unique_id = av.vehicle_unique_id
WHERE TRIM(av.vehicle_type) = '/'
AND av.policy_no = 'AU100012285'
;

SELECT * FROM [edw_temp].[metal_auto_vehicle_type]
;

