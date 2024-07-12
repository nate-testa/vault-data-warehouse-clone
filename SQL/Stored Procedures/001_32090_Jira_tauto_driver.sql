select top 100 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tauto_driver';
select * from [edw_core].[tauto_driver];
-- truncate table [edw_core].[tauto_driver];
-- EXEC [edw_core].[sp_tauto_driver];



-- tauto_driver
SELECT TOP 10 sdip_points_no, * FROM edw_core.tauto_driver;

SELECT sdip_points_no, COUNT(1) as row_count
FROM edw_core.tauto_driver 
GROUP BY sdip_points_no
;




-- select distinct acctvof.Field, acctvof.label, acctvo.ObjectType
select COUNT(1)
from edw_stage.AccountTransactionVersionObject as acctvo
inner join edw_stage.AccountTransactionVersionObjectField as acctvof
on acctvof.VersionObjectId = acctvo.Id
where 1=1
and acctvof.field = 'SDIPPoints'
;

SELECT 
    acctvof.Value, acct.[State], p.[Name] AS ProductName, p.ProductLine, acctvof.[Group], acctvo.ObjectType, COUNT(1) AS row_count
FROM [edw_stage].[AccountTransaction] AS acct
INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
WHERE 1=1
-- and acct.PolicyNumber = 'AU200024439'
AND acctvof.Field = 'SDIPPoints'
AND acctvof.Value IS NOT NULL
GROUP BY acctvof.Value, acct.[State], p.[Name], p.ProductLine, acctvof.[Group], acctvo.ObjectType
;

