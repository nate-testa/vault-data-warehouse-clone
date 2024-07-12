update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tpel_location';
select * from [edw_core].[tpel_location] where policy_no = 'EX400047811';--6858
select count(1) from [edw_core].[tpel_location];--7229
truncate table [edw_core].[tpel_location];
EXEC [edw_core].[sp_tpel_location];


update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_location';
select * from [edw_core].[tquote_pel_location];
select COUNT(1) from [edw_core].[tquote_pel_location];--4613
truncate table [edw_core].[tquote_pel_location];
EXEC [edw_core].[sp_tquote_pel_location];


update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_location_wip';
select * from [edw_core].[tquote_pel_location];
select COUNT(1) from [edw_core].[tquote_pel_location];--4613
truncate table [edw_core].[tquote_pel_location];
EXEC [edw_core].[sp_tquote_pel_location_wip];

/*
it is related to this ticket : https://dev.azure.com/vaultinsurance/Data/_sprints/taskboard/Data%20Team/Data/Sprint18?workitem=6427
 
So we have to add a column to tpel_location called primary_location_in (DDL complete in UAT) 
step 1 : we need to locate the 'PrimaryLocationId' field in edw_stage.[AccountTransactionVersionObjectField] AS acctvof table
step 2: join edw_stage.[AccountTransactionVersionObject] acctvo with edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.ReferenceObjectId = acctvo.id
step 3 : find the index number using the acctvo.[index] column which identifies the the primaryLocationId = index (4) which in turn signifies acctvo.index =4 meaning we should look at acctvo.ObjectGroupIdentifier = location#4 as the primary location 
Step 4 : now we know location#4 is the primary location, so set this as primary_location_in = Y in tpel_location 
*/

/* PK
    [policy_no] ASC,
    [effective_dt] ASC,
    [transaction_seq_no] ASC,
    [location_no] ASC
*/

--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'EX400047811'
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
,acctvof_2 AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE ReferenceObjectId in (select Id from acctvo)
)

--***All
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
select * from acctvof;
select * from acctvof_2;--3077058

--***Filters
-- SELECT '****acct****' as acct, acct.*, '****acctv****' as acctv, acctv.*, '****acctvo****' as acctvo, acctvo.*, '****acctvof****' as acctvof, acctvof.* 
-- FROM acct
-- INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
-- INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
-- INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
-- WHERE 1=1 
-- AND acctvof.Field = 'PrimaryLocationId'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'ExtendedLiabilityLocation'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'
;

--*******************************
--****FIND VALUE INTO A TABLE****
--*******************************

WITH tbl AS (
    SELECT *
        -- acct.PolicyNumber as policy_no, 
        -- acct.EffectiveDate as effective_dt,
        -- acct.PolicyChangeNumber as transaction_seq_no, 
        -- acctvo.[index],
        -- acctvof.[field],
        -- acctvof.[value],
        -- acctvo.ObjectGroupIdentifier,
    from edw_stage.[AccountTransaction] acct
    inner join edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
    inner join edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
    inner join edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.ReferenceObjectId = acctvo.id
    where 1=1
    and acct.PolicyNumber is not null 
    and acct.[State] = 'ISSUED'
    and acctvo.ObjectType = 'Location'
    and acctvof.Field = 'PrimaryLocationId'
    -- and acct.PolicyNumber in ('EX400047811','EX100003779-01')
    and acct.PolicyNumber in ('EX400047811')
)

-- select policy_no, effective_dt, transaction_seq_no, count(1) from tbl group by policy_no, effective_dt, transaction_seq_no having count(1) > 1
select * from tbl
;

SELECT * FROM edw_core.tpel_location 
-- WHERE policy_no in ('EX400047811','EX100003779-01')
WHERE policy_no = 'EX400047811'
;


--check policies with more that one primary_location_in = Y
select policy_no, effective_dt, transaction_seq_no, count(1), count(primary_location_in) 
from edw_core.tpel_location 
group by policy_no, effective_dt, transaction_seq_no 
having count(1) > 1
;

--check quotes with more that one primary_location_in = Y
select quote_no, effective_dt, transaction_seq_no, count(1), count(primary_location_in) 
from edw_core.tquote_pel_location
group by quote_no, effective_dt, transaction_seq_no 
having count(1) > 1
;

