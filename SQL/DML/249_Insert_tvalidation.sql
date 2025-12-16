INSERT INTO edw_core.tvalidation_sql
 (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)

SELECT 'Claim workday ITD reserve feed - null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_workday_itd_reserve_feed where monthend is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim workday ITD reserve feed - duplicate' AS commercial_validation_sql_desc ,	
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_workday_itd_reserve_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim workday reserve feed- null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_workday_reserve_feed where monthend is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim workday reserve feed- duplicate' AS commercial_validation_sql_desc ,	
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_workday_reserve_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim workday payment feed- null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_workday_payment_feed where monthend is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim workday payment feed - duplicate' AS commercial_validation_sql_desc ,	
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_workday_payment_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday ITD reserve feed- null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_litigation_workday_itd_reserve_feed where monthend is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday ITD reserve feed - duplicate' AS commercial_validation_sql_desc ,	
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_litigation_workday_itd_reserve_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday reserve feed- null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_litigation_workday_reserve_feed where monthend is null' AS source_sql ,   
 'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday reserve feed - duplicate' AS commercial_validation_sql_desc ,
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_workday_reserve_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
 'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday payment feed- null monthend' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.claim_litigation_workday_payment_feed where monthend is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Claim litigation workday payment feed - duplicate' AS commercial_validation_sql_desc ,
'select count(*) from (select monthend, count(distinct etl_audit_sk) AS etl_count from edw_integration.claim_litigation_workday_payment_feed group by monthend having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday ceded premium feed- null accouting_date' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.policy_workday_ceded_premium_feed where accounting_date is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday ceded premium feed - duplicate' AS commercial_validation_sql_desc ,
'select count(*) from (select accounting_date, count(distinct etl_audit_sk) AS etl_count from edw_integration.policy_workday_ceded_premium_feed group by accounting_date having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday written premium feed- null accouting_date' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.policy_workday_written_premium_feed where accounting_date is null' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday written premium feed - duplicate' AS commercial_validation_sql_desc ,
'select count(*) from (select accounting_date, count(distinct etl_audit_sk) AS etl_count from edw_integration.policy_workday_written_premium_feed group by accounting_date having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday unearned premium feed- null accouting_date' AS commercial_validation_sql_desc ,	
'select count(distinct etl_audit_sk) from edw_integration.policy_workday_unearned_premium_feed  where accounting_date is null' AS source_sql ,   
 'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Policy workday unearned premium feed - duplicate' AS commercial_validation_sql_desc ,
'select count(*) from (select accounting_date, count(distinct etl_audit_sk) AS etl_count from edw_integration.policy_workday_unearned_premium_feed  group by accounting_date having count(distinct etl_audit_sk)  > 1 ) t' AS source_sql ,   
'select 0' AS target_sql ,'Y' AS active_in ,'Monthly' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts