-- 94	Written premium validation
UPDATE edw_core.tvalidation_result
SET source_sql = '
select @source_ct =   
(  
    select sum(premium_amt) 
    from   
    edw_core.tpolicy_transaction pt  
    inner join edw_core.tdate d on pt.accouting_month_sk=d.date_sk  
    where  
    actual_dt = EOMONTH(''var_actual_dt'')  AND premium_amt!=0 and pt.accouting_month_sk = d.date_sk  
    AND GREATEST(pt.transaction_dt_sk,pt.transaction_effective_dt_sk)< = d.date_sk  
)  
+  
( 
    select sum(commission_amt) 
    from   
    edw_core.tpolicy_transaction pt  
    inner join edw_core.tdate d on pt.accouting_month_sk=d.date_sk  
    where
    actual_dt = EOMONTH(''var_actual_dt'')  and commission_amt!=0  and pt.accouting_month_sk = d.date_sk 
)'
WHERE
    validation_sql_desc = 'Written premium validation'

-- 95	Inforce premium/Unearned Premium validation

UPDATE edw_core.tvalidation_result
SET source_sql = '
select @source_ct = sum(tpts.premium_amt)    
from    
edw_core.tpolicy_transaction_summary tpts  
INNER JOIN edw_core.tdaily_inforce_policy dip on dip.policy_sk = tpts.policy_sk  
inner join edw_core.tdate d on tpts.month_sk=d.date_sk  
inner join edw_core.tdate di on dip.inforce_dt_sk=di.date_sk  
LEFT JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpts.internal_coverage_sk  
WHERE  tpts.month_sk= d.date_sk  
AND (tic.internal_coverage_category_nm = ''Premium'' OR tic.internal_coverage_desc like ''Subscriber Contribution%'')  
AND tpts.transaction_effective_dt_sk < = d.date_sk  AND tpts.expiration_dt_sk > d.date_sk  
and d.actual_dt = EOMONTH(''var_actual_dt'')   and di.actual_dt = ''var_actual_dt''
'
WHERE
    validation_sql_desc = 'Inforce premium/Unearned Premium validation'


-- 96	Inforce count/Unearned policy count validation

UPDATE edw_core.tvalidation_result
SET source_sql = '
select @source_ct = count(distinct dip.policy_sk)    
from edw_core.tdate d  
INNER JOIN edw_core.tdaily_inforce_policy dip on dip.inforce_dt_sk =d.date_sk    
WHERE d.actual_dt = ''var_actual_dt''
'
WHERE
    validation_sql_desc = 'Inforce premium/Unearned Premium validation'


-- 114	tpolicy_summary - total earned premium comparison to tpolicy_transaction_summary

UPDATE edw_core.tvalidation_result
SET source_sql = '
select @source_ct=  count(*)  
from  (     
select summ.policy_sk, sum(summ.mtd_premium_amt) wp, sum(earned_premium_amt) ep   
from 
edw_core.tpolicy_summary summ   
inner join edw_core.tdate td on td.date_sk = summ.month_sk   
where td.yearmonth <= FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM'')   
and policy_sk in    
(    
    select distinct policy_sk     
    from edw_core.tpolicy_transaction_summary pts, edw_core.tdate td      
    where td.date_sk = pts.month_sk and td.yearmonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM''))     
    group by summ.policy_sk  ) a   
    full join    
    (    
     select summ.policy_sk, sum(summ.premium_amt) wp, sum(earned_premium_amt) ep    
     from 
        edw_core.tpolicy_transaction_summary summ     
        inner join edw_core.tdate td on td.date_sk = summ.month_sk   
        where td.yearmonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM'')    
        group by summ.policy_sk   
    ) b on a.policy_sk = b.policy_sk    
where a.ep-b.ep not between -0.1 and 0.1 or a.policy_sk is null or b.policy_sk is null
'
WHERE
    validation_sql_desc = 'tpolicy_summary - total earned premium comparison to tpolicy_transaction_summary'



