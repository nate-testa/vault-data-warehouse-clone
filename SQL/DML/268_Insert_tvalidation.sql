INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Policies missing primary insured' as validation_sql_desc ,
'select count(*)
from
(
select policy_no,effective_dt,transaction_seq_no
from edw_core.tpolicy_insured 
where effective_dt >=''2025-01-01'' 
group by policy_no,effective_dt,transaction_seq_no 
having sum(case when primary_insured_in=''Yes'' then 1 else 0 end)=0
) as a' AS source_sql,
       'select  0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;