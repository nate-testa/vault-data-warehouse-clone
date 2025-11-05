--tpel_vehicle
select top 100 * from edw_core.tetl_audit where process_nm like '%home_additional_coverage%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_thome_additional_coverage','sp_tquote_home_additional_coverage','sp_tquote_home_additional_coverage_wip');
select COUNT(1) from [edw_core].[thome_additional_coverage];
select COUNT(1) from [edw_core].[tquote_home_additional_coverage];
select COUNT(1) from [edw_core].[tquote_home_additional_coverage_wip];
update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_thome_additional_coverage','sp_tquote_home_additional_coverage','sp_tquote_home_additional_coverage_wip');
truncate table [edw_core].[thome_additional_coverage];
truncate table [edw_core].[tquote_home_additional_coverage];
truncate table [edw_core].[tquote_home_additional_coverage_wip];
EXEC [edw_core].[sp_thome_additional_coverage];
EXEC [edw_core].[sp_tquote_home_additional_coverage];
EXEC [edw_core].[sp_tquote_home_additional_coverage_wip];


--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'HO200030244'
    ) 
    -- OR PolicyNumber LIKE 'CO100051662%'
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

--***All
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
-- select * from acctvof;

--***Filters
SELECT 
    '****acct****' as acct, acct.*, 
    '****acctv****' as acctv, acctv.*, 
    '****acctvo****' as acctvo, acctvo.*, 
    '****acctvof****' as acctvof, acctvof.*,
    'End'
FROM acct
INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
WHERE 1=1 
AND acctvof.Field = '%OtherStructuresOnTheResidencePremisesIncreasedLimit%'
-- AND acct.PolicyChangeNumber = 1
-- AND acct.PolicyNumber is not null 
-- AND acct.[State] ='ISSUED'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'ExtendedLiabilityLocation'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'
;

--check data
select
other_structures_on_the_residence_premises_increased_limit_in ,
other_structures_on_the_residence_premises_increased_limit_amt,
other_structures_on_the_residence_premises_increased_limit_desc
from
edw_core.thome_additional_coverage
where policy_no = 'HO200030244'
;

SELECT  acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt,acct.PolicyChangeNumber,
acct.IssuedDate,acctv.RiskStateCode,
acctvof.[field],acctvof.[value],acctvof.*,
CASE WHEN acct.ExternalSourceId IS NULL THEN 'Metal' Else 'AV2' END as source_system_nm
FROM edw_stage.[AccountTransaction] acct
INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
INNER  JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
INNER JOIN  edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
Where acctvof.[field] IN ('CoverageBDescription','CovreageBSublimit')
and acct.PolicyNumber in ('HO200030244')
;