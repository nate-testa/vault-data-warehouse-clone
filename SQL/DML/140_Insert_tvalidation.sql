INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'HSB inforce feed validation - ceded annual premium is 0' AS validation_sql_desc ,
       'select count(*)
 FROM 
                (
                    select policy_sk, i.annual_premium_amt
                    from edw_core.tdaily_inforce_policy as i
                    inner join edw_core.tdate as d ON i.inforce_dt_sk = d.date_sk
                    where product_sk in (1,5)
                    and d.actual_dt = cast(getdate()-1  as date)
                ) AS p
            inner JOIN
                (
                    select pt.policy_sk,SUM(pt.ceded_annual_premium_amt) as ceded_premium_amt
                    from edw_core.tpolicy_transaction as pt
                     inner join edw_core.tdate d on pt.expiration_dt_sk = d.date_sk --and d.actual_dt>cast(getdate() as date)
                   inner join edw_core.tdate d2 on pt.transaction_effective_dt_sk = d2.date_sk
                    inner join edw_core.tdate d3 on pt.transaction_dt_sk=d3.date_sk
                    inner join edw_core.tinternal_coverage as ic on pt.internal_coverage_sk = ic.internal_coverage_sk 
                    inner join edw_core.thome_additional_coverage hac on hac.home_coverage_sk=pt.coverage_sk
                    and d2.actual_dt<=cast(getdate()-1  as date) and d3.actual_dt<=cast(getdate()-1  as date)
                    where ic.internal_coverage_cd in (''Service Line'',''System Protection'', ''Systems Protection'',''Cyber Protection'') 
                    and (hac.serviceline_protection_in = ''Yes'' or hac.home_cyber_protection_coverage_in = ''Yes'' or hac.home_systems_protection_in = ''Yes'')
                    group by pt.policy_sk
                ) AS pt 
                ON pt.policy_sk = p.policy_sk 
                where p.annual_premium_amt<>0 and ceded_premium_amt=0' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts