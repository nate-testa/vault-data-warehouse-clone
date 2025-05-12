select top 10 * from edw_core.tetl_audit where process_nm like '%py%';
select * from edw_core.tetl_control where process_nm = 'py_majesco_billing';
-- EXEC edw_core.sp_upd_tetl_control 'py_majesco_billing','2025-04-19';
-- update edw_core.tetl_control set last_source_extract_ts = '2025-01-01' where process_nm = 'py_majesco_billing';


select top 10 act.BindDate as transactiondate,act.BindDate	
from edw_stage.AccountTransaction act
;