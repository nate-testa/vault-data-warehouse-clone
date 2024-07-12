-- tauto_vehicle_coverage
SELECT TOP 10 daytime_running_light_in , * FROM edw_core.tauto_vehicle_coverage;
SELECT daytime_running_light_in, COUNT(1) as row_count 
FROM edw_core.tauto_vehicle_coverage GROUP BY daytime_running_light_in;

SELECT daytime_running_light_in , * FROM edw_core.tauto_vehicle_coverage where policy_no = 'AU200024439';
SELECT * FROM edw_core.tpolicy where policy_no = 'AU200024439';

SELECT 
    acctvof.Value, acct.[State], p.[Name] AS ProductName, p.ProductLine, COUNT(1) AS row_count
FROM [edw_stage].[AccountTransaction] AS acct
INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 1=1
-- and acct.PolicyNumber = 'AU200024439'
AND acctvof.Field = 'DaytimeRunningLightIndicator'
AND acctvof.Value IS NOT NULL
GROUP BY acctvof.Value, acct.[State], p.[Name], p.ProductLine
;



select distinct acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group]
-- select COUNT(1)
from edw_stage.AccountTransactionVersionObject as acctvo
inner join edw_stage.AccountTransactionVersionObjectField as acctvof
on acctvof.VersionObjectId = acctvo.Id
where 1=1
-- and acctvof.field = 'DaytimeRunningLightIndicator'
and acctvof.field like '%ight%'
;

