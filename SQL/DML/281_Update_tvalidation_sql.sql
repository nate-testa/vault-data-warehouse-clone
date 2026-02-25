
-- 81 Snapsheet Validation- Cancelled approved reserves/payments
update edw_core.tvalidation_sql 
set target_sql = 'select 9'
where
	validation_sql_desc= 'Snapsheet Validation- Cancelled approved reserves/payments'