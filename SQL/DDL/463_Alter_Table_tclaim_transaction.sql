ALTER TABLE edw_core.tclaim_transaction DROP COLUMN defense_cost_in;
ALTER TABLE edw_core.tclaim_transaction DROP COLUMN adjusting_other_reserve_amt;
ALTER TABLE edw_core.tclaim_transaction DROP COLUMN adjusting_other_paid_amt;
ALTER TABLE edw_core.tclaim_transaction DROP COLUMN refund_indemnity_paid_amt;
ALTER TABLE edw_core.tclaim_transaction DROP COLUMN refund_expense_paid_amt;

EXEC sp_rename 'edw_core.tclaim_transaction.subro_reserve_amt', 'subrogation_recovery_reserve_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.salvage_reserve_amt', 'salvage_recovery_reserve_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.subro_expense_reserve_amt', 'subrogation_recovery_expense_reserve_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.salvage_expense_reserve_amt', 'salvage_recovery_expense_reserve_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.subro_recovery_amt', 'subrogation_recovery_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.salvage_expense_paid_amt', 'salvage_expense_recovery_amt', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_transaction.subro_expense_paid_amt', 'subrogation_expense_recovery_amt', 'COLUMN';


ALTER TABLE edw_core.tclaim_transaction ADD claim_cost_category_sk int;
ALTER TABLE edw_core.tclaim_transaction ADD  defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_recovery_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_recovery_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_recovery_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_recovery_expense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_recovery_expense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_recovery_expense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  subrogation_recovery_defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  salvage_recovery_defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_recovery_defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_recovery_defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_recovery_defense_reserve_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  defense_paid_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_expense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_expense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_expense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  subrogation_defense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  salvage_defense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  deductible_defense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  reinsurance_defense_recovery_amt decimal(15,2);
ALTER TABLE edw_core.tclaim_transaction ADD  overpayment_defense_recovery_amt decimal(15,2);

ALTER TABLE edw_core.tclaim_transaction ADD CONSTRAINT fk_tclaim_transaction_cost_category_sk FOREIGN KEY (claim_cost_category_sk) REFERENCES  edw_core.tclaim_cost_category(claim_cost_category_sk);
			
