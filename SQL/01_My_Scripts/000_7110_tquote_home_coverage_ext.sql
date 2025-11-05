--tpel_vehicle
select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_home_coverage_ext%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_tquote_home_coverage_ext');
select COUNT(1) from [edw_stage].[tquote_home_coverage_ext];
select * from [edw_stage].[tquote_home_coverage_ext];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tquote_home_coverage_ext');
-- truncate table [edw_stage].[tquote_home_coverage_ext];
-- EXEC [edw_core].[sp_tquote_home_coverage_ext];

SELECT * FROM edw_core.vquote_home_coverage_ext;




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
