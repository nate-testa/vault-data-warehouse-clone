select top 100 * from edw_core.tetl_audit where process_nm like '%sp_tcommercial%' ORDER BY 1 DESC;
select top 100 * from edw_core.tetl_control where process_nm like '%sp_tcommercial_policy%';

-- Error Number:515 Error State:2 Error Severity:16 Error Procedure:edw_core.sp_tcommercial_policy_transaction Error Line:182 Error Message:Cannot insert the value NULL into column 'customer_sk', table 'vault_edw.edw_commercial.tcommercial_policy_transaction'; column does not allow nulls. INSERT fails.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE 1=1
    AND PolicyNumber IN ('M5020201','M5020201')
    -- AND Id = '72d606ad-7078-4d23-a5cd-01ed80d4d186'
)
,acctv AS (
    SELECT * FROM edw_stage.AccountTransactionVersion 
    WHERE AccountTransactionId in (select Id from acct)
    
)
,acctvo AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObject 
    WHERE AccountTransactionVersionId in (select Id from acctv)
    AND ObjectType = 'TowerquotaShare'
    AND Id = 3030462
)
,acctvof AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE VersionObjectId in (select Id from acctvo)
)

--***All
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
select * from acctvof-- where Field = 'LimitPerClaim';

--***Filters
SELECT 
    -- '****acct****' as acct, acct.*, 
    -- '****acctv****' as acctv, acctv.*, 
    -- '****acctvo****' as acctvo, acctvo.*, 
    -- '****acctvof****' as acctvof, acctvof.*,
    'End'
FROM acct
INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
WHERE 1=1 
-- AND acctvof.Field like '%LossDate%'
AND acctvof.Field in ('MailingAddressLine1')
-- AND acct.PolicyChangeNumber = 1
-- AND acct.PolicyNumber is not null 
-- AND acct.[State] ='ISSUED'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'ExtendedLiabilityLocation'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'
;

--***********************
--**** update errors ****
--***********************
--AccountTransaction
WITH tbl AS (
    SELECT *
    FROM edw_stage.AccountTransaction
    WHERE PolicyNumber 
    -- in ('M5020201')
    IN (SELECT DISTINCT QUOTE_NO FROM edw_temp.tcommercial_quote_subjectivity_temp3 WHERE commercial_quote_history_sk IS NULL)
)
select * from tbl
-- UPDATE edw_stage.AccountTransaction SET CreatedDate = '1900-01-01 00:00:00' WHERE Id in (select Id from tbl)
-- UPDATE edw_stage.AccountTransaction SET IssuedDate = '1900-01-01 00:00:00' WHERE Id in (select Id from tbl)
;

--Account
WITH tbl AS (
    SELECT *
    FROM edw_stage.Account
    WHERE PolicyNumber 
    -- in ('M5020201')
    IN (SELECT distinct quote_no FROM edw_temp.tcommercial_quote_temp3 WHERE product_cd is null)
    -- IN (SELECT distinct PolicyNumber FROM edw_stage.Account WHERE CreatedDate = '1900-01-01 00:00:00' OR UpdatedDate = '1900-01-01 00:00:00')
)
select * from tbl
-- UPDATE edw_stage.Account SET CreatedDate = '1900-01-01 00:00:00', UpdatedDate = '1900-01-01 00:00:00' WHERE Id in (select Id from tbl)
;
--***********************
--**** update errors ****
--***********************

--POLICY--
--Create Backup
-- select * into edw_temp.[tcommercial_policy_subjectivity_06252025] from [edw_commercial].[tcommercial_policy_subjectivity];
-- select * into edw_temp.[tcommercial_policy_quota_share_06252025] from [edw_commercial].[tcommercial_policy_quota_share];
-- select * into edw_temp.[tcommercial_policy_tower_06252025] from [edw_commercial].[tcommercial_policy_tower];
-- select * into edw_temp.[tcommercial_policy_transaction_06252025] from [edw_commercial].[tcommercial_policy_transaction];
-- select * into edw_temp.[tcommercial_policy_coverage_06252025] from [edw_commercial].[tcommercial_policy_coverage];
-- select * into edw_temp.[tcommercial_policy_history_06252025] from [edw_commercial].[tcommercial_policy_history];
-- select * into edw_temp.[tcommercial_policy_06252025] from [edw_commercial].[tcommercial_policy];
-- select * into edw_temp.[tcommercial_daily_inforce_policy_06252025] from [edw_commercial].[tcommercial_daily_inforce_policy];
-- select * into edw_temp.[tcommercial_policy_summary_06252025] from [edw_commercial].[tcommercial_policy_summary];
-- select * into edw_temp.[tcommercial_renewal_summary_06252025] from [edw_commercial].[tcommercial_renewal_summary];
-- select * into edw_temp.[tcommercial_broker_summary_06252025] from [edw_commercial].[tcommercial_broker_summary];

/*
--Delete all data
delete from [edw_commercial].[tcommercial_policy_subjectivity]
delete from [edw_commercial].[tcommercial_policy_quota_share]
delete from [edw_commercial].[tcommercial_policy_tower]
delete from [edw_commercial].[tcommercial_policy_transaction]
delete from [edw_commercial].[tcommercial_policy_coverage]
delete from [edw_commercial].[tcommercial_broker_summary]
delete from [edw_commercial].[tcommercial_renewal_summary]
delete from [edw_commercial].[tcommercial_policy_summary]
delete from [edw_commercial].[tcommercial_daily_inforce_policy]
delete from [edw_commercial].[tcommercial_policy_history]
delete from [edw_commercial].[tcommercial_policy];

--Reset identity
truncate table [edw_commercial].[tcommercial_policy_subjectivity]
truncate table [edw_commercial].[tcommercial_policy_quota_share]
truncate table [edw_commercial].[tcommercial_policy_tower]
truncate table [edw_commercial].[tcommercial_policy_transaction]
truncate table [edw_commercial].[tcommercial_policy_coverage]
truncate table [edw_commercial].[tcommercial_broker_summary]
truncate table [edw_commercial].[tcommercial_renewal_summary]
truncate table [edw_commercial].[tcommercial_policy_summary]
truncate table [edw_commercial].[tcommercial_daily_inforce_policy]
DBCC CHECKIDENT('edw_commercial.tcommercial_policy_history',RESEED,0);
DBCC CHECKIDENT('edw_commercial.tcommercial_policy',RESEED,0);



update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' 
where process_nm in (
     'sp_tcommercial_policy'
    ,'sp_tcommercial_policy_update_cancels'
    ,'sp_tcommercial_policy_history'
    ,'sp_tcommercial_policy_history_update'
    ,'sp_tcommercial_policy_coverage'
    ,'sp_tcommercial_policy_tower'
    ,'sp_tcommercial_policy_quota_share'
    ,'sp_tcommercial_policy_subjectivity'
    ,'sp_tcommercial_policy_transaction'
    ,'sp_tcommercial_daily_inforce_policy'
    ,'sp_tcommercial_policy_summary'
    ,'sp_tcommercial_renewal_summary'
    ,'sp_tcommercial_broker_summary'
)
;
*/

-- EXEC [edw_core].[sp_tcommercial_policy];
-- EXEC [edw_core].[sp_tcommercial_policy_update_cancels];
-- EXEC [edw_core].[sp_tcommercial_policy_history];
-- EXEC [edw_core].[sp_tcommercial_policy_history_update];
-- EXEC [edw_core].[sp_tcommercial_policy_coverage];
-- EXEC [edw_core].[sp_tcommercial_policy_tower];
-- EXEC [edw_core].[sp_tcommercial_policy_quota_share];
-- EXEC [edw_core].[sp_tcommercial_policy_subjectivity];
-- EXEC [edw_core].[sp_tcommercial_policy_transaction];
-- EXEC [edw_core].[sp_tcommercial_daily_inforce_policy];
-- EXEC [edw_core].[sp_tcommercial_policy_summary];
-- EXEC [edw_core].[sp_tcommercial_renewal_summary];
-- EXEC [edw_core].[sp_tcommercial_broker_summary];


SELECT 'tcommercial_policy' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy]
UNION ALL
SELECT 'tcommercial_policy_history' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_history]
UNION ALL
SELECT 'tcommercial_policy_coverage' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_coverage]
UNION ALL
SELECT 'tcommercial_policy_transaction' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_transaction]
UNION ALL
SELECT 'tcommercial_policy_tower' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_tower]
UNION ALL
SELECT 'tcommercial_policy_quota_share' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_quota_share]
UNION ALL
SELECT 'tcommercial_policy_subjectivity' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_subjectivity]
UNION ALL
SELECT 'tcommercial_daily_inforce_policy' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].tcommercial_daily_inforce_policy
UNION ALL
SELECT 'tcommercial_policy_summary' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].tcommercial_policy_summary
UNION ALL
SELECT 'tcommercial_renewal_summary' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].tcommercial_renewal_summary
UNION ALL
SELECT 'tcommercial_broker_summary' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].tcommercial_broker_summary
;


---------------------------------------------------------------------------------------------------------------------------------------------------------------
--QUOTE--
--Create Backup
-- select * into edw_temp.[tcommercial_quote_subjectivity_06252025] from [edw_commercial].[tcommercial_quote_subjectivity];
-- select * into edw_temp.[tcommercial_quote_quota_share_06252025] from [edw_commercial].[tcommercial_quote_quota_share];
-- select * into edw_temp.[tcommercial_quote_tower_06252025] from [edw_commercial].[tcommercial_quote_tower];
-- select * into edw_temp.[tcommercial_quote_transaction_06252025] from [edw_commercial].[tcommercial_quote_transaction];
-- select * into edw_temp.[tcommercial_quote_coverage_06252025] from [edw_commercial].[tcommercial_quote_coverage];
-- select * into edw_temp.[tcommercial_quote_history_06252025] from [edw_commercial].[tcommercial_quote_history];
-- select * into edw_temp.[tcommercial_quote_06252025] from [edw_commercial].[tcommercial_quote];

/*
--Delete all data
delete from [edw_commercial].[tcommercial_quote_subjectivity]
delete from [edw_commercial].[tcommercial_quote_quota_share]
delete from [edw_commercial].[tcommercial_quote_tower]
delete from [edw_commercial].[tcommercial_quote_transaction]
delete from [edw_commercial].[tcommercial_quote_coverage]
delete from [edw_commercial].[tcommercial_quote_history]
delete from [edw_commercial].[tcommercial_quote];

--Reset identity
truncate table [edw_commercial].[tcommercial_quote_subjectivity]
truncate table [edw_commercial].[tcommercial_quote_quota_share]
truncate table [edw_commercial].[tcommercial_quote_tower]
truncate table [edw_commercial].[tcommercial_quote_transaction]
truncate table [edw_commercial].[tcommercial_quote_coverage]
DBCC CHECKIDENT('edw_commercial.tcommercial_quote_history',RESEED,0);
DBCC CHECKIDENT('edw_commercial.tcommercial_quote',RESEED,0);


update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' 
where process_nm in (
    'sp_tcommercial_quote',
    'sp_tcommercial_quote_update',
    'sp_tcommercial_quote_history_wip',
    'sp_tcommercial_quote_history',
    'sp_tcommercial_quote_history_update',
    'sp_tcommercial_quote_coverage_wip',
    'sp_tcommercial_quote_coverage',
    'sp_tcommercial_quote_tower_wip',
    'sp_tcommercial_quote_tower',
    'sp_tcommercial_quote_quota_share_wip',
    'sp_tcommercial_quote_quota_share',
    'sp_tcommercial_quote_subjectivity_wip',
    'sp_tcommercial_quote_subjectivity',
    'sp_tcommercial_quote_transaction_wip',
    'sp_tcommercial_quote_transaction'
)
;
*/

-- EXEC [edw_core].[sp_tcommercial_quote];
-- EXEC [edw_core].[sp_tcommercial_quote_update];
-- EXEC [edw_core].[sp_tcommercial_quote_history_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_history];
-- EXEC [edw_core].[sp_tcommercial_quote_history_update];
-- EXEC [edw_core].[sp_tcommercial_quote_coverage_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_coverage];
-- EXEC [edw_core].[sp_tcommercial_quote_tower_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_tower];
-- EXEC [edw_core].[sp_tcommercial_quote_quota_share_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_quota_share];
-- EXEC [edw_core].[sp_tcommercial_quote_subjectivity_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_subjectivity];
-- EXEC [edw_core].[sp_tcommercial_quote_transaction_wip];
-- EXEC [edw_core].[sp_tcommercial_quote_transaction];


SELECT 'tcommercial_quote' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote]
UNION ALL   
SELECT 'tcommercial_quote_history' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_history]
UNION ALL
SELECT 'tcommercial_quote_coverage' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_coverage]
UNION ALL
SELECT 'tcommercial_quote_transaction' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_transaction]
UNION ALL
SELECT 'tcommercial_quote_tower' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_tower]
UNION ALL
SELECT 'tcommercial_quote_quota_share' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_quota_share]
UNION ALL
SELECT 'tcommercial_quote_subjectivity' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_quote_subjectivity]
;


-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tcommercial_quote_update');
-- EXEC [edw_core].[sp_tcommercial_quote_update];

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--DATAMART--
--Execute all
delete from [edw_commercial].[tcommercial_policy_summary]
delete from [edw_commercial].[tcommercial_daily_inforce_policy];

update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' 
where process_nm in (
    'sp_tcommercial_daily_inforce_policy',
    'sp_tcommercial_policy_summary'
)
;

EXEC [edw_core].[sp_tcommercial_daily_inforce_policy];
EXEC [edw_core].[sp_tcommercial_policy_summary];


SELECT 'tcommercial_policy_summary' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_policy_summary]
UNION ALL
SELECT 'tcommercial_daily_inforce_policy' AS table_name, COUNT(1) AS record_count FROM [edw_commercial].[tcommercial_daily_inforce_policy]
;

-----------------------------------------------------------------
-----------------------------------------------------------------
select Number, * from edw_stage.Account where PolicyNumber = 'A5010246';

select top 10 * from edw_commercial.tcommercial_policy where policy_no = 'A5010246';
select top 10 * from edw_commercial.tcommercial_quote where quote_no = '1309677';

select top 10 policy from edw_commercial.tcommercial_quote_history where quote_no = '1309677';

select * from edw_temp.tcommercial_quote_temp3 where customer_id is null;

select PrimaryInsuredId, * FROM edw_temp.tcommercial_quote_temp1 tmp1
left join edw_stage.Insured ins on tmp1.PrimaryInsuredId = ins.Id
where ins.ReferenceCode is null
;

SELECT 
    acc.PrimaryInsuredId, acc.PolicyNumber, acc.*
    ,CASE 
        WHEN acc.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
        ELSE 4 --(Metal)
    END source_system_sk 
FROM edw_stage.Account acc 
left join edw_stage.Product pr on acc.ProductId = pr.id
WHERE pr.ProductLine = 'CommercialLines' 
-- AND greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts
and acc.PrimaryInsuredId is null
;

SELECT * FROM edw_stage.AccountTransaction WHERE AccountId IN ('a6f3a6ee-7600-4707-b7ad-a39a4f89fc51','638bdc65-9d53-46be-b879-daf1dc330cab','9de0b0c6-0c7e-4cbf-99b3-9331b7e0a5fa');

SELECT 
CreatedDate,UpdatedDate 
;
-- UPDATE edw_stage.Account 
-- SET CreatedDate = '1900-01-01 00:00:00', UpdatedDate = '1900-01-01 00:00:00'
WHERE Id IN ('a6f3a6ee-7600-4707-b7ad-a39a4f89fc51','638bdc65-9d53-46be-b879-daf1dc330cab','9de0b0c6-0c7e-4cbf-99b3-9331b7e0a5fa');



SELECT top 10 * FROM [edw_commercial].[tcommercial_quote] order by 1;

--------------------------------------------------------------------------
-- *** Case dups on sp_tcommercial_policy_history ***
-- Error Number:2627 Error State:1 Error Severity:14\rError Procedure:edw_core.sp_tcommercial_policy_history Error Line:233\r
-- Error Message:Violation of UNIQUE KEY constraint 'uidx_tcommercial_policy_history_policy_no_effective_dt_transactionseqno'. 
-- Cannot insert duplicate key in object 'edw_commercial.tcommercial_policy_history'. The duplicate key value is (M5020214, 2025-05-01, 0).

EXEC SP_HELP 'edw_commercial.tcommercial_policy_history';
-- UNIQUE policy_no, effective_dt, transaction_seq_no

SELECT policy_no, effective_dt, transaction_seq_no, COUNT(1) rc  FROM edw_temp.tcommercial_policy_history_temp5 GROUP BY policy_no, effective_dt, transaction_seq_no;

-- Policies that already exist on final table
SELECT tmp.*
FROM edw_commercial.tcommercial_policy_history tbl
INNER JOIN edw_temp.tcommercial_policy_history_temp5 tmp
ON tbl.policy_no = tmp.policy_no
ON tbl.effective_dt = tmp.effective_dt
ON tbl.transaction_seq_no = tmp.transaction_seq_no
;

SELECT transaction_ts, [policy_no], [effective_dt], [transaction_seq_no] FROM edw_temp.tcommercial_policy_history_temp5;
SELECT transaction_ts, [policy_no], [effective_dt], [transaction_seq_no] FROM edw_commercial.tcommercial_policy_history WHERE policy_no in ('C1530308','M5020214');
SELECT BindDate, PolicyNumber, EffectiveDate, PolicyChangeNumber, * FROM edw_stage.AccountTransaction WHERE PolicyNumber = 'M5020206';

select * from edw_core.tetl_control where process_nm like '%tcommercial_policy_history%';

select edw_core.fn_get_last_source_extract_ts('sp_tcommercial_policy_history') as last_source_extract_ts;
SELECT Id, BindDate FROM edw_stage.AccountTransaction WHERE PolicyNumber = 'M5020214' AND BindDate > edw_core.fn_get_last_source_extract_ts('sp_tcommercial_policy_history'); --'2025-05-06 15:57:29.6013484';--Policy to change
SELECT Id, BindDate, * FROM edw_stage.AccountTransaction WHERE Id IN ('4f607711-53d1-4634-81f3-5e2cb4808ddb','086f07ea-9c3e-4c60-ac67-5c64aae69bf0');
/*
Id	                                    BindDate
086f07ea-9c3e-4c60-ac67-5c64aae69bf0	2025-06-02 15:26:59.1228252
4f607711-53d1-4634-81f3-5e2cb4808ddb	2024-11-04 21:00:07.2724434
*/
-- Temporal Update
-- UPDATE edw_stage.AccountTransaction SET BindDate = '1900-01-01 00:00:00' WHERE Id = '086f07ea-9c3e-4c60-ac67-5c64aae69bf0';

-- Return to original values
-- UPDATE edw_stage.AccountTransaction SET BindDate = '2025-06-02 15:26:59.1228252' WHERE Id = '086f07ea-9c3e-4c60-ac67-5c64aae69bf0';




--------------------------------------------------------------------------
-- *** error on sp_tcommercial_quote
-- The MERGE statement attempted to UPDATE or DELETE the same row more than once. This happens when a target row matches more than one source row
select edw_core.fn_get_last_source_extract_ts('sp_tcommercial_quote') as last_source_extract_ts;

select * from edw_temp.tcommercial_quote_temp3 where quote_no = '1279277';
select * from edw_stage.Account where [Number] = '1279277';

WITH tbl AS (
    select Source.* from edw_commercial.tcommercial_quote AS Target
    inner join edw_temp.tcommercial_quote_temp3 AS Source
    ON Source.quote_no = Target.quote_no
        AND (
                    (Source.quote_term = 'New'  AND YEAR(Target.effective_dt) = YEAR(Source.effective_dt))
                    OR
                    (Source.quote_term != 'New'  AND Target.effective_dt = Source.effective_dt)
            )
)
, dups AS (
    SELECT quote_no, COUNT(1) rc FROM tbl GROUP BY quote_no HAVING COUNT(1) > 1
)
-- SELECT * FROM tbl
-- SELECT * FROM dups
-- SELECT * FROM edw_temp.tcommercial_quote_temp3 WHERE quote_no in (select quote_no from dups)
SELECT Id, CreatedDate, UpdatedDate, * FROM edw_stage.Account WHERE [Number] IN (select quote_no from dups)
;
/*
Id	                                    CreatedDate	                UpdatedDate
0566c07a-df74-4746-9459-7ad8eb770c84	2024-03-01 18:47:13.2108708	2025-06-02 03:00:00.3973858
e4329c9e-56c2-490f-a959-91a113833a87	2025-05-16 18:50:50.1632514	2025-05-29 19:47:40.3039821
*/
-- Temporal Update
-- UPDATE edw_stage.Account SET CreatedDate = '1900-01-01 00:00:00', UpdatedDate = '1900-01-01 00:00:00' WHERE Id = '0566c07a-df74-4746-9459-7ad8eb770c84';
-- UPDATE edw_stage.Account SET CreatedDate = '1900-01-01 00:00:00', UpdatedDate = '1900-01-01 00:00:00' WHERE Id = 'e4329c9e-56c2-490f-a959-91a113833a87';

-- Return to original values
-- UPDATE edw_stage.Account SET CreatedDate = '2024-03-01 18:47:13.2108708', UpdatedDate = '2025-06-02 03:00:00.3973858' WHERE Id = '0566c07a-df74-4746-9459-7ad8eb770c84';
-- UPDATE edw_stage.Account SET CreatedDate = '2025-05-16 18:50:50.1632514', UpdatedDate = '2025-05-29 19:47:40.3039821' WHERE Id = 'e4329c9e-56c2-490f-a959-91a113833a87';
;

--------------------------------------------------------------------------
-- *** error on sp_tcommercial_quote
-- Violation of UNIQUE KEY constraint 'uidx_tcommercial_quote_quote_no_effective_dt'. Cannot insert duplicate key in object 'edw_commercial.tcommercial_quote'
select edw_core.fn_get_last_source_extract_ts('sp_tcommercial_quote') as last_source_extract_ts;
EXEC sp_help'edw_commercial.tcommercial_quote';
-- quote_no, effective_dt -- Unique Key

select count(1) rc from edw_temp.tcommercial_quote_temp3;
select * from edw_temp.tcommercial_quote_temp3 where quote_no = '1288087';
select * from edw_commercial.tcommercial_quote where quote_no = '1288087';

WITH merge_tbl AS (
    SELECT 
        Source.*,
        CASE 
            WHEN Target.quote_no IS NULL THEN 'INSERT'
            ELSE 'UPDATE'
        END AS merge_action
    FROM edw_temp.tcommercial_quote_temp3 AS Source
    LEFT JOIN edw_commercial.tcommercial_quote AS Target
        ON Source.quote_no = Target.quote_no
        AND (
            (Source.quote_term = 'New' AND YEAR(Target.effective_dt) = YEAR(Source.effective_dt)) OR
            (Source.quote_term != 'New' AND Target.effective_dt = Source.effective_dt)
        )
)
,rows_with_conflict AS (
    select a.* 
    from merge_tbl as a
    inner join edw_commercial.tcommercial_quote as b
    on a.quote_no = b.quote_no 
    and cast(a.effective_dt as date) = cast(b.effective_dt as date)
    where a.merge_action = 'INSERT'
)
select * from merge_tbl where quote_no = '1288087'
-- select * from rows_with_conflict
;

select * from edw_temp.tcommercial_quote_temp3 where quote_no = '1279277';
select * from edw_stage.Account where [Number] = '1279277';



SELECT TABLE_SCHEMA, TABLE_NAME, 'DROP TABLE edw_temp.' + TABLE_NAME + ';' AS QRY
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_temp'
  AND TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME LIKE '%commercial%2025%';


