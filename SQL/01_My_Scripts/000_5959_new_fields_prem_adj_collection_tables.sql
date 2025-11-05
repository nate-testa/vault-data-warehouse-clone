select * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;


--tcollection_class_type
select count(1), max(transaction_dt) from [edw_core].[tcollection_class_type];
select policy_no, transaction_seq_no, class_type ,
[blanket_premium_adjustment_method] ,
[blanket_premium_adjustment_factor] ,
[blanket_premium_adjustment_retention] ,
[blanket_premium_adjustment_retention_reason] ,
[scheduled_premium_adjustment_method] ,
[scheduled_premium_adjustment_factor] ,
[scheduled_premium_adjustment_retention] ,
[scheduled_premium_adjustment_retention_reason]
from [edw_core].[tcollection_class_type] where policy_no = 'CO200023788';

update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tcollection_class_type');
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tcollection_scheduled_item');
truncate table [edw_core].[tcollection_scheduled_item];
delete [edw_core].[tcollection_class_type];
EXEC [edw_core].[sp_tcollection_class_type];
EXEC [edw_core].[sp_tcollection_scheduled_item];
select * from [edw_core].[tcollection_class_type]
where 1=1
    and [blanket_premium_adjustment_method] is not null 
    and [blanket_premium_adjustment_factor] is not null 
    and [blanket_premium_adjustment_retention] is not null 
    and [blanket_premium_adjustment_retention_reason] is not null 
    and [scheduled_premium_adjustment_method] is not null 
    and [scheduled_premium_adjustment_factor] is not null 
    and [scheduled_premium_adjustment_retention] is not null 
    and [scheduled_premium_adjustment_retention_reason] is not null 
;

select distinct 
-- [group] ,
TRIM(REPLACE(REPLACE([group],'(Scheduled)',''),'(Blanket)',''))
from [edw_stage].[AccountTransactionVersionPremiumFactor] where Coverage = 'Collections';

SELECT distinct class_type FROM [edw_core].[tcollection_class_type];

--tquote_collection_class_type

-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_tquote_collection_class_type Error Line:178 Error Message:Violation of UNIQUE KEY constraint 'uidx_tquote_collection_class_type_quote_no_effective_dt_transeq_class'. Cannot insert duplicate key in object 'edw_core.tquote_collection_class_type'. The duplicate key value is (1013465, 2023-09-11, 1, Not Bank Vaulted Jewelry).
select * from [edw_temp].[tquote_collection_class_type_temp1] where quote_no is null;

select quote_no, EffectiveDate, Number ,ClassType, count(1) from [edw_temp].[tquote_collection_class_type_temp1] group by quote_no, EffectiveDate, Number ,ClassType having count(1) > 1;

delete [edw_stage].[AccountTransaction] where PolicyNumber
in (
'1013465'
,'1013465'
,'HO200024296'
)
;
select count(1) from [edw_core].[tquote_collection_class_type];
select * from [edw_core].[tquote_collection_class_type]; 
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tquote_collection_class_type');
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tquote_collection_scheduled_item');
truncate table [edw_core].[tquote_collection_scheduled_item];
delete from [edw_core].[tquote_collection_class_type];
EXEC [edw_core].[sp_tquote_collection_class_type];
EXEC [edw_core].[sp_tquote_collection_class_type_wip];
EXEC [edw_core].[sp_tquote_collection_scheduled_item];
EXEC [edw_core].[sp_tquote_collection_scheduled_item_wip];
select * from [edw_core].[tquote_collection_class_type]
where 1=1
    and [blanket_premium_adjustment_method] is not null 
    and [blanket_premium_adjustment_factor] is not null 
    and [blanket_premium_adjustment_retention] is not null 
    and [blanket_premium_adjustment_retention_reason] is not null 
    and [scheduled_premium_adjustment_method] is not null 
    and [scheduled_premium_adjustment_factor] is not null 
    and [scheduled_premium_adjustment_retention] is not null 
    and [scheduled_premium_adjustment_retention_reason] is not null 
;

--########################
--## Check Foreing Keys ##
--########################
SELECT 
    OBJECT_NAME(f.parent_object_id) AS 'Main Table',
    OBJECT_NAME (f.referenced_object_id) AS 'Secondary Table',
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS 'Column in Main Table',
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS 'Column in Secondary Table'
FROM 
    sys.foreign_keys AS f
INNER JOIN 
    sys.foreign_key_columns AS fc ON f.object_id = fc.constraint_object_id
WHERE 
    f.referenced_object_id = OBJECT_ID('edw_core.tquote_collection_class_type')
;



SELECT TOP 10 * FROM [edw_stage].[Account];
SELECT TOP 10 * FROM [edw_stage].[AccountPremium];
SELECT TOP 10 * FROM [edw_stage].[AccountPremiumFactor];