select top 100 * from edw_core.tetl_audit where process_nm like '%tpolicy_form%' order by etl_audit_sk desc;
select count(1) from [edw_core].[tpolicy_form];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('tpolicy_form');
-- truncate table [edw_core].[tpolicy_form];
-- EXEC [edw_core].[sp_tpolicy_form];

select top 100 * from edw_core.tetl_audit where process_nm like '%tquote_form%' order by etl_audit_sk desc;
select count(1) from [edw_core].[tquote_form];

-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('tquote_form');
-- truncate table [edw_core].[tquote_form];
-- EXEC [edw_core].[sp_tquote_form];



SELECT * FROM [edw_temp].[tpolicy_form_temp1];

SELECT * FROM edw_core.tpolicy_form;
SELECT * FROM edw_core.tquote_form;


SELECT top 100 * FROM edw_core.tpolicy;
SELECT top 100 * FROM edw_core.tpolicy_history;
SELECT top 100 * FROM edw_core.tpolicy_transaction;
SELECT top 100 * FROM [edw_stage].[AccountTransactionVersionForm];
SELECT top 100 * FROM [edw_stage].[AccountTransaction];
