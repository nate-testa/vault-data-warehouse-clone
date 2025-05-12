update edw_core.tvalidation_sql 
set source_sql = 'select count(*) from (    
select c.claim_no     from edw_core.tclaim_transaction ct, edw_core.tclaim c    
where ct.claim_sk = c.claim_sk     
and c.claim_status = ''CLOSED''    
group by c.claim_no     
having sum(ct.loss_reserve_amt+ct.expense_reserve_amt+ct.subrogation_recovery_reserve_amt+ct.salvage_recovery_reserve_amt+
				ct.salvage_recovery_expense_reserve_amt+ct.subrogation_recovery_expense_reserve_amt+
				ct.defense_reserve_amt+ct.deductible_recovery_reserve_amt+
				ct.reinsurance_recovery_reserve_amt+ct.overpayment_recovery_reserve_amt+ct.deductible_recovery_expense_reserve_amt+
				ct.reinsurance_recovery_expense_reserve_amt+ct.overpayment_recovery_expense_reserve_amt+
				ct.subrogation_recovery_defense_reserve_amt+ct.salvage_recovery_defense_reserve_amt+
				ct.deductible_recovery_defense_reserve_amt+ct.reinsurance_recovery_defense_reserve_amt+
				ct.overpayment_recovery_defense_reserve_amt) <> 0) a' 
where validation_sql_desc = 	'tclaim_transaction - total reserves <> 0 for closed claim'

update edw_core.tvalidation_sql 
set source_sql = 'SELECT count(*) from ( select claim_feature_sk from edw_core.tclaim_feature  a group by claim_feature_sk having 
 SUM( COALESCE( ( a.loss_paid_amt + a.expense_paid_amt + a.defense_paid_amt), 0) )<0 ) a' , target_sql='select 0'
where validation_sql_desc = 	'tclaim_feature - negative paid'
 
 