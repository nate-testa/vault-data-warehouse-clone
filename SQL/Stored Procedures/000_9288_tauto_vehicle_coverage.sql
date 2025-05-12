select top 10 * from edw_core.tetl_audit where process_nm like '%py%';
select * from edw_core.tetl_control where process_nm = 'py_majesco_billing';
-- EXEC edw_core.sp_upd_tetl_control 'py_majesco_billing','2025-04-19';
-- update edw_core.tetl_control set last_source_extract_ts = '2025-01-01' where process_nm = 'py_majesco_billing';


--Normal Tables
select distinct acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group]
-- select *
from edw_stage.AccountTransactionVersionObject as acctvo
inner join edw_stage.AccountTransactionVersionObjectField as acctvof
on acctvof.VersionObjectId = acctvo.Id
where 1=1
-- AND p.[Name] = 'Marine Boat & Yacht'
-- AND p.ProductLine = 'PersonalLines'
-- AND acctvo.ObjectType = 'Watercraft'
and acctvof.field = 'AgreedValueCoverage'
-- and acctvof.Field like '%LimitPerClaim%'
-- and acctvof.label like '%xcess%'
-- and [Group] in ('Location Details')
-- and acctvo.ObjectType IN ('PersonalExcessLiability','Location')
;

SELECT DISTINCT [Group], Coverage, Field
FROM [edw_stage].[AccountTransactionVersionPremiumFactor]
-- WHERE Coverage IN ('%AgreedValueCoverage%')
WHERE Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor'
,'Added First Party','Added Personal Injury Protection','Basic First Party','Customized','Fire','Property Protection Insurance','Theft','Uninsured Bodily Injury','Uninsured Property Damage','Uninsured Motorist'
)
;

SELECT DISTINCT [Group], Field
FROM [edw_stage].[AccountTransactionVersionObjectField]
WHERE 1=1
-- AND Field = 'AgreedValueCoverage'
AND [Group] IN ('Vehicle Coverages')
-- WHERE [Group] IN ('Vehicle','Registration','Symbols','Symbols - ISO','Vehicle Coverages','AntiTheftDevice','Discounts','Surcharge','Security and Safety Features')
;



SELECT TOP 10 * FROM [edw_stage].[AccountTransactionVersionPremiumFactor];

SELECT * 
FROM [edw_stage].[AccountTransaction] AS acct
INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
WHERE acct.[State] = 'ISSUED'
-- AND acct.IssuedDate > @last_source_extract_ts
AND acctvpf.Coverage IN ('Bodily Injury', 'Property Damage', 'Medical Payments', 'Underinsured Motorist', 'Other Than Collision', 'Collision', 'Personal Injury Protection', 'Extended Towing and Labor'
,'Added First Party','Added Personal Injury Protection','Basic First Party','Customized','Fire','Property Protection Insurance','Theft','Uninsured Bodily Injury','Uninsured Property Damage','Uninsured Motorist'
)
AND p.[Name] = 'Automobile'
AND p.ProductLine = 'PersonalLines'
;


select top 10 agreed_value_coverage_in, flood_deductible_pc from edw_core.tauto_vehicle_coverage;
select top 10 agreed_value_coverage_in, flood_deductible_pc from edw_core.tquote_auto_vehicle_coverage;

