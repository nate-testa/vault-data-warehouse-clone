-- metal_product_fieldname_datafix
-- Product- 
-- Home
-- Auto
-- PEL
-- Lux


select * from edw_core.tpolicy where policy_no =  'AU100077484-02';
select * from edw_core.tauto_vehicle where policy_no =  'AU100077484-02' order by vehicle_no;
select * from edw_core.tauto_vehicle_coverage where policy_no =  'AU100077484-02' order by transaction_seq_no, vehicle_no;



select avc.policy_no, avc.effective_dt, avc.transaction_seq_no, avc.vehicle_no, av.vehicle_make, av.vehicle_model, av.vehicle_model_year, av.vehicle_vin, av.vehicle_unique_id
from edw_core.tauto_vehicle_coverage avc
inner join edw_core.tauto_vehicle av on av.auto_vehicle_sk = avc.auto_vehicle_sk
where avc.policy_no =  'AU100077484-02' 
order by avc.transaction_seq_no, avc.vehicle_no
;

SELECT acctvo.* 
FROM [edw_stage].[AccountTransaction] acct
INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
WHERE 1=1
AND p.[Name] = 'Automobile'
AND p.ProductLine = 'PersonalLines'
AND acct.[State] = 'ISSUED'
AND acct.PolicyNumber = 'AU100077484-02'
AND acctvo.ObjectType = 'Vehicle'
AND acct.PolicyChangeNumber = 1
ORDER BY acctvo.[Index]
;

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN ('AU100077484-02') 
    AND PolicyChangeNumber = 1
)
,acctv AS (
    SELECT * FROM edw_stage.AccountTransactionVersion 
    WHERE AccountTransactionId in (select Id from acct)
)
,acctvo AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObject 
    WHERE AccountTransactionVersionId in (select Id from acctv)
)
,acctvof AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE VersionObjectId in (select Id from acctvo)
)

SELECT * FROM acctvo WHERE ObjectType = 'Vehicle'
;


--Cruce final
SELECT acct.PolicyNumber AS policy_no, acct.EffectiveDate AS effective_dt, acct.policychangenumber AS transaction_seq_no, acctvo.[UniqueId] as vehicle_unique_id, av.policyimageidentifierid, av.PolicyObjectIdentifierId, 
acctvof.Id AS acctvof_Id, acctvof.VersionObjectId, acctvof.Field AS acctvof_Field, acctvof.[Value] AS METAL_vehicle_type, av.vehicle_type AS AV2_vehicle_type
-- INTO [edw_temp].[metal_Auto_VehicleType_datafix]
FROM [edw_temp].[av2_auto_vehicle] av
INNER JOIN [edw_stage].[AccountTransaction] acct ON acct.PolicyNumber = av.policy_no
INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acct.Id = acctv.AccountTransactionId AND acctv.ExternalSourceId = av.policyimageidentifierid AND acctv.PolicyNumber = av.policy_no
INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id AND acctvo.ExternalSourceId = av.PolicyObjectIdentifierId
INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 1=1
    AND acctvo.ObjectType = 'Vehicle'
    AND acctvof.Field = 'VehicleType'
;


SELECT * FROM [edw_temp].[metal_Auto_VehicleType_datafix]
;
