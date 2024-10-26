-- vault_livevox_load_call_detail_report.py
-- insert into edw_core.tetl_control (process_nm, last_source_extract_ts, update_ts) values('py_call_detail_report','2000-01-01 00:00:00',null);
-- truncate table edw_stage.stage_livevox;
-- EXEC [edw_core].[sp_upd_tetl_control] 'py_call_detail_report','1900-01-01 00:00:00.0000000';

select * from edw_core.tetl_control where process_nm = 'py_call_detail_report';

select create_ts, source_file_name, count(1) as ct 
from edw_stage.stage_livevox 
group by create_ts, source_file_name
order by 1 desc;


select count(1) from edw_stage.stage_livevox ;--3531--33944

select create_ts, CONVERT(VARCHAR(8), CAST(CallConnectTimeCT  AS DATETIME), 112) AS CallConnectTimeCT, source_file_name, count(1) as ct 
from edw_stage.stage_livevox    
group by create_ts, source_file_name, CONVERT(VARCHAR(8), CAST(CallConnectTimeCT  AS DATETIME), 112) 
order by 2;

select COUNT(1) as ct from edw_stage.stage_livevox;
select top 10 * from edw_stage.stage_livevox;
SELECT edw_core.fn_get_last_source_extract_ts('py_call_detail_report') as last_loaded_date;


-- DELETE FROM edw_stage.stage_livevox WHERE source_file_name IN ();

SELECT COUNT(1) 
-- DELETE
FROM edw_stage.stage_livevox 
WHERE source_file_name IN (
     'Vault_Call_Detail_Report_20240908.txt'
    ,'Vault_Call_Detail_Report_20240909.txt'
    ,'Vault_Call_Detail_Report_20240910.txt'
    ,'Vault_Call_Detail_Report_20240911.txt'
    ,'Vault_Call_Detail_Report_20240912.txt'
    ,'Vault_Call_Detail_Report_20240913.txt'
    ,'Vault_Call_Detail_Report_20240914.txt'
    ,'Vault_Call_Detail_Report_20240915.txt'
);




select CONVERT(VARCHAR(8), CAST(CallConnectTimeCT  AS DATETIME), 112) AS CallConnectTimeCT 
from edw_stage.stage_livevox 
-- WHERE source_file_name <> '2024_LiveVox_Call_Detail_Report.csv'
-- GROUP BY 1
-- ORDER BY 1
;


-- exec sp_help 'edw_stage.stage_livevox';