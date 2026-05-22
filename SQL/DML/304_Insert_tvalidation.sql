INSERT INTO edw_core.tvalidation_sql 
(validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'tpolicy_transaction - ceded premium but no gross premium' AS validation_sql_desc ,
'
select count(*)
from
edw_core.tdaily_inforce_policy as i
inner join edw_core.tdate as d ON i.inforce_dt_sk = d.date_sk and d.actual_dt = cast(getdate()-1  as date)
and i.product_sk in (1,5)  
inner join edw_core.tpolicy_transaction as pt on pt.policy_sk = i.policy_sk
inner join edw_core.tpolicy_history ph on ph.policy_history_sk = pt.policy_history_sk
inner join edw_core.tdate d2 on pt.transaction_effective_dt_sk = d2.date_sk and d2.actual_dt<=cast(getdate()-1  as date)
inner join edw_core.tdate d3 on pt.transaction_dt_sk=d3.date_sk and d3.actual_dt<=cast(getdate()-1  as date)
inner join edw_core.tinternal_coverage as ic on pt.internal_coverage_sk = ic.internal_coverage_sk
inner join edw_core.thome_additional_coverage hac on hac.home_coverage_sk=pt.coverage_sk
where ic.internal_coverage_cd in (''Service Line'',''System Protection'', ''Systems Protection'',''Cyber Protection'')
and (hac.serviceline_protection_in = ''Yes'' or hac.home_cyber_protection_coverage_in = ''Yes'' or hac.home_systems_protection_in = ''Yes'')
and pt.premium_amt = 0
and pt.ceded_premium_amt != 0 
' AS source_sql ,
'select 0' AS target_sql ,
'Y' AS active_in ,
'Daily' AS frequency_desc ,
getdate() AS create_ts ,
getdate() AS update_ts

UNION

SELECT
'tpolicy_history - transaction effective date after policy expiration date for New Business policies' AS validation_sql_desc ,
'select count(*) from
edw_core.tpolicy p
	inner join edw_core.tpolicy_history ph on p.policy_sk = ph.policy_sk
	inner join edw_core.tdaily_inforce_policy as i on i.policy_history_sk = ph.policy_history_sk
	inner join edw_core.tdate as d ON i.inforce_dt_sk = d.date_sk and d.actual_dt = cast(getdate()-1  as date)
where p.policy_term = ''New'' and ph.transaction_effective_dt > ph.expiration_dt 
' AS source_sql ,
'select 0' AS target_sql ,
'Y' AS active_in ,
'Daily' AS frequency_desc ,
getdate() AS create_ts ,
getdate() AS update_ts;