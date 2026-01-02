--94 (Written premium validation)
update edw_core.tvalidation_sql
set source_sql='select @source_ct = 
(
select sum(premium_amt) from 
edw_core.tpolicy_transaction pt
inner join edw_core.tdate d on pt.accouting_month_sk=d.date_sk
where
actual_dt = EOMONTH(''var_actual_dt'')
AND premium_amt!=0 and pt.product_sk <> 10
and pt.accouting_month_sk = d.date_sk
AND GREATEST(pt.transaction_dt_sk,pt.transaction_effective_dt_sk)< = d.date_sk
)
+
(
select sum(commission_amt) from 
edw_core.tpolicy_transaction pt
inner join edw_core.tdate d on pt.accouting_month_sk=d.date_sk
where
actual_dt = EOMONTH(''var_actual_dt'')
and commission_amt!=0
and pt.accouting_month_sk = d.date_sk and pt.product_sk <> 10
)
'
where validation_sql_desc = 'Written premium validation';

--95 (Inforce premium/Unearned Premium validation)
update edw_core.tvalidation_sql
set source_sql='select @source_ct = sum(tpts.premium_amt)
from
edw_core.tpolicy_transaction_summary tpts
inner join edw_core.tdate d on tpts.month_sk=d.date_sk
LEFT JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpts.internal_coverage_sk
INNER JOIN edw_core.tdaily_inforce_policy dip on dip.policy_sk = tpts.policy_sk	and dip.inforce_dt_sk =d.date_sk
WHERE
	tpts.month_sk= d.date_sk
	AND (tic.internal_coverage_category_nm = ''Premium'' OR tic.internal_coverage_desc like ''Subscriber Contribution%'')
	AND tpts.transaction_effective_dt_sk < = d.date_sk
	AND tpts.expiration_dt_sk > d.date_sk
	and d.actual_dt = EOMONTH(''var_actual_dt'')
    and dip.product_sk <> 10'
where validation_sql_desc = 'Inforce premium/Unearned Premium validation';

--96 (Inforce count/Unearned policy count validation)
update edw_core.tvalidation_sql
set source_sql='select @source_ct=count(distinct dip.policy_sk)
from
edw_core.tdate d
INNER JOIN 
edw_core.tdaily_inforce_policy dip on dip.inforce_dt_sk =d.date_sk
WHERE d.actual_dt = EOMONTH(''var_actual_dt'') and product_sk <> 10'
where validation_sql_desc = 'Inforce count/Unearned policy count validation';

--115 (tinternal_coverage_summary - compared to tpolicy_summary)
update edw_core.tvalidation_sql
set source_sql='select count(*)
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
where td.date_sk = summ.month_sk and product_sk in(1,3,5,2,4,6)
and td.actual_dt >= dateadd(mm,-1,getdate())
group by td.yearmonth
) n
where o.yearmonth = n.yearmonth
) a
where wp_diff not between -0.9 and 0.9 or ep_diff not between -0.9 and 0.9 '
where validation_sql_desc = 'tinternal_coverage_summary - compared to tpolicy_summary';

--81 (Snapsheet Validation- Cancelled approved reserves/payments)
update edw_core.tvalidation_sql
set target_sql='select 8'
where validation_sql_desc = 'Snapsheet Validation- Cancelled approved reserves/payments';