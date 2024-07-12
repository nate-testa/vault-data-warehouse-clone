insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tclaim_feature - negative paid' as validation_sql_desc
		,' select count(*)
from
(
select claim_feature_sk
from edw_core.tclaim_feature  a
group by claim_feature_sk
having SUM(
COALESCE(
(
a.loss_paid_amt             +
a.expense_paid_amt          +
a.adjusting_other_paid_amt  +
a.refund_indemnity_paid_amt +
a.refund_expense_paid_amt
), 0)
)<0
) a' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;


insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'thome_coverage - multiple deductibles' as validation_sql_desc
		,'SELECT count(*)
FROM edw_core.thome_coverage
WHERE
  (CASE WHEN NULLIF(wind_or_hailstorm_deductible, '''') IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN NULLIF(hurricane_or_named_storm_deductible, '''') IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN NULLIF(hurricane_deductible, '''') IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN NULLIF(named_storm_deductible, '''') IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN NULLIF(tornado_or_hailstorm_deductible, '''') IS NOT NULL THEN 1 ELSE 0 END) > 1' as source_sql
		,'select 0' as target_sql
		,'Y' as active_in
		,'Daily' as frequency_desc
		,getdate() as create_ts
		,getdate() as update_ts;