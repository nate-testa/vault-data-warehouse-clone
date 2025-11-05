select top 100 * from edw_core.tetl_audit where process_nm = 'sp_tadditional_interest' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm = 'sp_tadditional_interest';

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm IN('sp_tauto_vehicle','sp_tauto_vehicle_coverage','sp_tauto_vehicle_coverage_rapa','sp_tadditional_interest');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm IN('sp_tadditional_interest');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm IN('sp_tquote_additional_interest','sp_tquote_additional_interest_wip');
-- TRUNCATE TABLE [edw_core].[tadditional_interest];
-- TRUNCATE TABLE [edw_core].[tquote_additional_interest];
-- TRUNCATE TABLE [edw_core].[tauto_vehicle_coverage];
-- TRUNCATE TABLE [edw_core].[tauto_vehicle_coverage_rapa];
-- DELETE FROM [edw_core].[tauto_vehicle];
SELECT COUNT(1) FROM [edw_core].[tadditional_interest];--4242
SELECT COUNT(1) FROM [edw_core].[tquote_additional_interest];
-- SELECT COUNT(1) FROM [edw_core].[tauto_vehicle_coverage];
-- SELECT COUNT(1) FROM [edw_core].[tauto_vehicle_coverage_rapa];
-- SELECT COUNT(1) FROM [edw_core].[tauto_vehicle];
-- EXEC [edw_core].[sp_tauto_vehicle];
-- EXEC [edw_core].[sp_tauto_vehicle_coverage];
-- EXEC [edw_core].[sp_tauto_vehicle_coverage_rapa];
-- EXEC [edw_core].[sp_tadditional_interest];
-- EXEC [edw_core].[sp_tquote_additional_interest];
-- EXEC [edw_core].[sp_tquote_additional_interest_wip];

SELECT * FROM [edw_core].[tadditional_interest] WHERE policy_no IN (
    -- 'AU200025827',
    -- 'AU200025904',
    'AU200025920'
);

SELECT * FROM edw_temp.[tadditional_interest_temp1] WHERE PolicyNumber = 'AU200025904';
SELECT * FROM edw_temp.[tadditional_interest_temp2] WHERE ReferenceObjectId in (1654135,1654145,1654136,1654144);

--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE 1=1
    AND PolicyNumber IN (        
        -- 'AU200025827',
        -- 'AU200025904'.
        'AU200025920'
        ) 
    AND [state] = 'ISSUED'
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
-- select distinct ReferenceObjectType from acctvof;

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
-- AND acct.PolicyChangeNumber = 1
-- AND acct.PolicyNumber is not null 
-- AND acct.[State] ='ISSUED'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'Vehicle'
AND acctvo.ObjectType = 'AdditionalInterest'
AND acctvof.Field = 'Vehicle'
-- AND acctvof.ReferenceObjectType = 'Vehicle'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'
;
-- ReferenceObjectId = '1653093'



select top 100 * from edw_stage.AccountTransactionVersion where id in ('173905','174046','174047');

select top 100 * from edw_stage.AccountTransaction where id in (
'a8434c91-2a1c-44dd-946f-3c1c471d8d02',
'54985653-cbf9-4259-94ff-3efae74829e5',
'f442ebbf-2de8-4891-9ef4-861751a62f04'
);

SELECT * FROM edw_stage.AccountTransactionVersionObject where ID in
(
'1654135',
'1654145',
'1653093',
'1654136',
'1654144')
;

SELECT top 100 * 
FROM [edw_core].[tauto_vehicle]
where vehicle_unique_id in (
'd359a11b-9e53-439d-95d3-b40eb5d60b50',
'9e0bcf23-4cd0-4cca-a598-282cf93c4d87',
'6eae577d-35a9-4b9c-90e4-5afe5b55dac3'
)
;

select count(1), count(auto_vehicle_sk) from [edw_core].[tadditional_interest];
SELECT COUNT(1), COUNT(vehicle_unique_id) FROM [edw_core].[tauto_vehicle];

SELECT * FROM [edw_core].[tauto_vehicle] WHERE policy_no IN (
    'AU200025827'
);



SELECT 
    acc.PolicyNumber,
    acct.[UniqueId],    
    acct.ObjectType,
    accto.[Group],
    accto.ReferenceObjectId,
    accto.ReferenceObjectType,
    acct2.[UniqueId],
    -- accto.*,
    av.auto_vehicle_sk
FROM
(
    SELECT
        *
    FROM [edw_stage].[AccountTransaction]
    WHERE
        [State] ='ISSUED' --- Review BOUND transactions
        AND PolicyNumber = 'AU200025827'
        --AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 removed
        -- AND GREATEST(IssuedDate)>@last_source_extract_ts --20230717 added
) acc
INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct2 
					ON accto.ReferenceObjectId = acct2.Id 
					AND accto.ReferenceObjectType = 'Vehicle'
					AND acct2.ObjectType = 'Vehicle' 
LEFT JOIN [edw_core].[tpolicy_history] his ON his.policy_no = acc.PolicyNumber AND his.effective_dt=acc.EffectiveDate AND his.transaction_seq_no = acc.policychangenumber
LEFT JOIN [edw_core].[tauto_vehicle] AS av
    ON av.policy_no = acc.PolicyNumber
    AND av.effective_dt = acc.EffectiveDate
    AND av.vehicle_unique_id = acct2.[UniqueId]
WHERE 1=1
--p.[Name]='Collections'
AND acct.ObjectType IN ('AdditionalInterest')--,'Vehicle')
-- AND accto.[Group] in ('Additional Interest','Vehicle')
;

SELECT * FROM [edw_stage].[AccountTransactionVersion] WHERE ID = 173905;
SELECT * FROM [edw_stage].[AccountTransactionVersionObject] WHERE ID IN (1653093,1653094);

SELECT DISTINCT AccountTransactionVersionId, UniqueId FROM edw_stage.AccountTransactionVersionObject ;


select top 100 *, versionobjectif from [edw_stage].[AccountTransactionVersionObject];


select * from edw_core.tquote_additional_interest;
select count(*) from edw_temp.tquote_additional_interest_bkup_20240814;--40504
select count(*) from edw_core.tquote_additional_interest;--40464
-- select * into edw_temp.tquote_additional_interest_bkup_20240814 from edw_core.tquote_additional_interest;
update edw_core.tetl_control set last_sourcE_extract_ts = '1900-01-01 00:00:00.0000000' where process_nm like '%sp_tquote_additional_interest%';
truncate table edw_core.tquote_additional_interest;
exec  edw_core.sp_tquote_additional_interest;
exec  edw_core.sp_tquote_additional_interest_wip;

select top 10 * from edw_temp.tquote_additional_interest_bkup_20240814;
select top 10 * from edw_core.tquote_additional_interest;



select top 100 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
select count(1) from [edw_integration].[policy_ivans_auto_feed];--38834
update edw_core.tetl_control set last_source_extract_ts = '2024-01-01 00:00:00' where process_nm = 'sp_policy_ivans_auto_feed';
-- select * into [edw_temp].[policy_ivans_auto_feed_bk_20240815] from [edw_integration].[policy_ivans_auto_feed];
-- truncate table [edw_integration].[policy_ivans_auto_feed];
EXEC [edw_core].[sp_policy_ivans_auto_feed];

SELECT * FROM edw_core.tauto_vehicle_coverage;

select distinct additional_interest_deleted_in from edw_core.tadditional_interest;

select top 10 * from [edw_integration].[policy_ivans_auto_feed] where PolicyNumber_031 = 'AU100191633-02';
select * from edw_core.tadditional_interest where policy_no = 'AU100191633-02';
select top 10 * from edw_core.tauto_vehicle_coverage where auto_vehicle_sk = 50600;