
SELECT * FROM edw_stage.stage_majesco_cash_activity;
SELECT count(1) FROM edw_stage.stage_majesco_cash_activity;--11043-215999-256795

SELECT [start_date], end_date, create_ts, COUNT(*) as rc
FROM edw_stage.stage_majesco_cash_activity 
GROUP BY [start_date], end_date, create_ts
ORDER BY cast([start_date] as date)
;

SELECT last_source_extract_ts 
FROM edw_core.tetl_control 
WHERE process_nm = 'py_majesco_billing'
;