-- insert into edw_core.tetl_control (process_nm, last_source_extract_ts, update_ts) values('py_lc360_file','2024-01-01 00:00:00',null);
SELECT * FROM edw_core.tetl_control WHERE process_nm = 'py_lc360_file';
UPDATE edw_core.tetl_control SET last_source_extract_ts = '2024-04-23 00:00:00' WHERE process_nm = 'py_lc360_file';

select COUNT(1) from [edw_stage].[stage_lc360];

-- truncate table [edw_stage].[stage_lc360];

