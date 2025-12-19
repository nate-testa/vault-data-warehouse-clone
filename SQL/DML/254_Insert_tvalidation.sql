INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tauto_policy_coverage - Auto policies with combined limit having uninsured_motorist_limit_amt populated' ,
'select count(*)
from edw_core.tauto_policy_coverage where limit_type = ''Combined''
and uninsured_motorist_limit_amt is not null'  AS source_sql ,
       'select  0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;