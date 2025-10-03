select top 10 * from edw_core.tetl_audit where process_nm like '%py%';
select * from edw_core.tetl_control where process_nm = 'py_majesco_billing';
-- EXEC edw_core.sp_upd_tetl_control 'py_majesco_billing','2025-04-19';
-- update edw_core.tetl_control set last_source_extract_ts = '2025-01-01' where process_nm = 'py_majesco_billing';
-- update edw_core.tetl_control set last_source_extract_ts = '2025-01-24' where process_nm = 'py_majesco_billing';

-- insert into edw_core.tetl_control where process_nm = 'py_majesco_billing';

SELECT 'stage_majesco_adjust_writeoff' AS Table_Name, COUNT(*) AS Rows_Loaded FROM edw_stage.stage_majesco_adjust_writeoff WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_agency_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_agency_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL  
SELECT 'stage_majesco_billing_fee', COUNT(*) FROM edw_stage.stage_majesco_billing_fee WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_cash_activity', COUNT(*) FROM edw_stage.stage_majesco_cash_activity WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_commission_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_commission_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_due_date_aging', COUNT(*) FROM edw_stage.stage_majesco_due_date_aging WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_policy_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
UNION ALL
SELECT 'stage_majesco_premium_activity_report', COUNT(*) FROM edw_stage.stage_majesco_premium_activity_report WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
;



/*
TRUNCATE TABLE edw_stage.stage_majesco_adjust_writeoff;
TRUNCATE TABLE edw_stage.stage_majesco_agency_level_monthly_commission_balance;
TRUNCATE TABLE edw_stage.stage_majesco_billing_fee;
TRUNCATE TABLE edw_stage.stage_majesco_cash_activity;
TRUNCATE TABLE edw_stage.stage_majesco_commission_disbursement_register;
TRUNCATE TABLE edw_stage.stage_majesco_disbursement_register;
TRUNCATE TABLE edw_stage.stage_majesco_due_date_aging;
TRUNCATE TABLE edw_stage.stage_majesco_policy_level_monthly_commission_balance;
TRUNCATE TABLE edw_stage.stage_majesco_premium_activity_report;
*/

SELECT CAST(create_ts AS DATE), CAST(GETDATE() AS DATE), COUNT(1) FROM edw_stage.stage_majesco_adjust_writeoff GROUP BY CAST(create_ts AS DATE);
-- SELECT TOP 10 * FROM edw_stage.stage_majesco_agency_level_monthly_commission_balance;
SELECT TOP 10 * FROM edw_stage.stage_majesco_billing_fee;
SELECT TOP 10 * FROM edw_stage.stage_majesco_cash_activity;
-- SELECT TOP 10 * FROM edw_stage.stage_majesco_commission_disbursement_register;
SELECT TOP 10 * FROM edw_stage.stage_majesco_disbursement_register;
-- SELECT TOP 10 * FROM edw_stage.stage_majesco_due_date_aging;
SELECT TOP 10 * FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance;
SELECT TOP 10 * FROM edw_stage.stage_majesco_premium_activity_report;


SELECT max(create_ts) FROM edw_stage.stage_majesco_agency_level_monthly_commission_balance;

SELECT count(1) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance where create_ts > '2025-04-17 21:04:48.000';--11318

-- DELETE edw_stage.stage_majesco_agency_level_monthly_commission_balance where create_ts > '2025-04-16 00:00:00.000';--11318

select * from edw_stage.stage_majesco_policy_level_monthly_commission_balance where accounting_month is null;--393216

select * from edw_stage.stage_majesco_policy_level_monthly_commission_balance where accounting_month is null;--393216

SELECT * FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance where accounting_month is not null;

TRUNCATE TABLE edw_stage.stage_majesco_policy_level_monthly_commission_balance;
SELECT COUNT(1) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance;--132705
SELECT COUNT(1) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance where accounting_month is null;--132705
SELECT top 1000 * FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance ;where policy_no like 'HO98290518636%';

EXEC SP_HELP 'edw_stage.stage_majesco_policy_level_monthly_commission_balance';

