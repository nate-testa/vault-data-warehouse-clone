INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tinternal_coverage_summary - compared to tpolicy_summary' ,
'select count(*)
from
(
select o.yearmonth,
o.wp wpo, n.wp wpn, n.wp-o.wp wp_diff, o.ep epo, n.ep epn, n.ep-o.ep ep_diff
from
(
select td.yearmonth,
sum(summ.mtd_premium_amt) wp, sum(earned_premium_amt) ep, count(*) ct
from edw_core.tpolicy_summary summ, edw_core.tdate td
where td.date_sk = summ.month_sk and product_sk in(1,3,5,2,4,6)
and td.actual_dt >= dateadd(mm,-1,getdate())
group by td.yearmonth
) o,
(
select td.yearmonth,
sum(summ.mtd_premium_amt) wp, sum(earned_premium_amt) ep, count(*) ct
from edw_core.tinternal_coverage_summary summ, edw_core.tdate td
where td.date_sk = summ.month_sk
and td.actual_dt >= dateadd(mm,-1,getdate())
group by td.yearmonth
) n
where o.yearmonth = n.yearmonth
) a
where wp_diff not between -0.9 and 0.9 or ep_diff not between -0.9 and 0.9 ' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;