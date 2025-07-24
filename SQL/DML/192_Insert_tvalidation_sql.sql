INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tpolicy_summary - total earned premium comparison to tpolicy_transaction_summary' ,
       'select count(*)
from
(
select summ.policy_sk, sum(summ.mtd_premium_amt) wp, sum(earned_premium_amt) ep
from edw_core.tpolicy_summary summ
inner join edw_core.tdate td on td.date_sk = summ.month_sk
where td.yearmonth <= FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM'')
and policy_sk in (select distinct policy_sk from edw_core.tpolicy_transaction_summary pts, edw_core.tdate td
where td.date_sk = pts.month_sk and td.yearmonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM''))
group by summ.policy_sk
) a
full join
(
select summ.policy_sk, sum(summ.premium_amt) wp, sum(earned_premium_amt) ep
from edw_core.tpolicy_transaction_summary summ
inner join edw_core.tdate td on td.date_sk = summ.month_sk
where td.yearmonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM'')
group by summ.policy_sk
) b on a.policy_sk = b.policy_sk
where a.ep-b.ep not between -0.00 and 0.0013 or a.policy_sk is null or b.policy_sk is null' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;