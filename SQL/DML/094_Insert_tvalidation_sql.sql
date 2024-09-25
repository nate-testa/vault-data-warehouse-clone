INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Cyber Protection Indicator/Amount mismatch' AS validation_sql_desc ,
       'select count(*) from edw_core.thome_additional_coverage where
(home_cyber_protection_coverage_in = ''Yes'' and (home_cyber_protection_coverage_limit_amt = ''0'' or home_cyber_protection_coverage_limit_amt is null)) OR
((home_cyber_protection_coverage_in = ''No'' or home_cyber_protection_coverage_in is null) and home_cyber_protection_coverage_limit_amt > ''0'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;


INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT 'Home Systems Protection Indicator/Amount mismatch' AS validation_sql_desc ,
       'select count(*) from edw_core.thome_additional_coverage where
(home_systems_protection_in = ''Yes'' and (home_systems_protection_limit_amt = ''0'' or home_systems_protection_limit_amt is null)) OR
((home_systems_protection_in = ''No'' or home_systems_protection_in is null) and home_systems_protection_limit_amt > ''0'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;