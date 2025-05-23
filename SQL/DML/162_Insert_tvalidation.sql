INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Written premium validation' AS validation_sql_desc ,
 'select @source_ct = 
(
select sum(premium_amt) from 
edw_core.tpolicy_transaction pt
inner join edw_core.tdate d on pt.accouting_month_sk=d.date_sk
where
actual_dt = EOMONTH(''var_actual_dt'')
AND premium_amt!=0
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
and pt.accouting_month_sk = d.date_sk
)
' AS source_sql ,
'select @target_ct=sum(amount) from edw_integration.policy_workday_written_premium_feed where accounting_date= EOMONTH(''var_actual_dt'')'  AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;


INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Inforce premium/Unearned Premium validation' AS validation_sql_desc ,
'select @source_ct = sum(tpts.premium_amt)
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
	and d.actual_dt = EOMONTH(''var_actual_dt'')'
	AS source_sql ,
'select @target_ct=sum(amount) from edw_integration.policy_workday_unearned_premium_feed where accounting_date = ''var_actual_dt''' AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Inforce count/Unearned policy count validation' AS validation_sql_desc ,
'select @source_ct=count(distinct dip.policy_sk)
from
edw_core.tdate d
INNER JOIN 
edw_core.tdaily_inforce_policy dip on dip.inforce_dt_sk =d.date_sk
WHERE d.actual_dt = EOMONTH(''var_actual_dt'')' AS source_sql ,
'select @target_ct=count(distinct policy_number) from edw_integration.policy_workday_unearned_premium_feed where accounting_date = EOMONTH(''var_actual_dt'')
and category = ''Premium''
' AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
       
INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Claim payment amount validation' AS validation_sql_desc ,
'SELECT @source_ct=SUM(a.loss_paid_amt+a.overpayment_recovery_amt+a.deductible_recovery_amt+
                            a.deductible_expense_recovery_amt+a.expense_paid_amt+a.overpayment_expense_recovery_amt+
                            a.deductible_defense_recovery_amt+a.defense_paid_amt+a.overpayment_defense_recovery_amt+
                            a.subrogation_recovery_amt+a.subrogation_defense_recovery_amt+
                            a.subrogation_expense_recovery_amt+
                            a.salvage_defense_recovery_amt + a.salvage_recovery_amt+
                            a.salvage_expense_recovery_amt
                            )
FROM edw_core.tclaim_transaction a
inner join edw_core.tdate d on a.transaction_dt_sk=d.date_sk
inner join edw_core.tclaim c on a.claim_sk=c.claim_sk
WHERE
c.underwriting_company_nm not like ''%Litigation%''
and d.actual_dt between DATEADD(DAY, 1, EOMONTH(''var_actual_dt'', -1)) and ''var_actual_dt''' AS source_sql ,
'select @target_ct=sum(paymentamount) from edw_integration.claim_workday_payment_feed where monthend= EOMONTH(''var_actual_dt'')
' AS target_sql ,
       'Y' AS active_in ,
       'Monthly' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;
