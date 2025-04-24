Alter Table edw_core.tcollection_class_type alter column policy_history_sk int not null

Alter Table edw_core.tcollection_scheduled_item alter column policy_history_sk int not null
Alter Table edw_core.tloss_history alter column policy_history_sk int not null
Alter Table edw_core.tpel_watercraft alter column policy_history_sk int not null
Alter Table edw_core.thome_coverage alter column policy_history_sk int not null
Alter Table edw_core.titem_summary alter column policy_history_sk int not null
Alter Table edw_core.thome_additional_coverage alter column policy_history_sk int not null
Alter Table edw_core.tinternal_coverage_inforce alter column policy_history_sk int not null
Alter Table edw_core.tinternal_coverage_summary alter column policy_history_sk int not null

Alter Table edw_core.tcollection_coverage alter column policy_history_sk int not null
Alter Table edw_core.tpolicy_insured alter column policy_history_sk int not null
Alter Table edw_core.tpel_coverage alter column policy_history_sk int not null
Alter Table edw_core.tpel_location alter column policy_history_sk int not null
Alter Table edw_core.tpel_vehicle alter column policy_history_sk int not null
Alter Table edw_core.tpel_driver alter column policy_history_sk int not null
Alter Table edw_core.tpel_driver_incident alter column policy_history_sk int not null
Alter Table edw_core.tpolicy_transaction_summary alter column policy_history_sk int not null


drop index if exists idx_tadditional_interest_policy_history_sk on edw_core.tadditional_interest
Alter Table edw_core.tadditional_interest alter column policy_history_sk int not null
CREATE NONCLUSTERED INDEX [idx_tadditional_interest_policy_history_sk] ON edw_core.tadditional_interest (policy_history_sk)


drop index if exists idx_tmortgagee_policy_history_sk on edw_core.tmortgagee
Alter Table edw_core.tmortgagee alter column policy_history_sk int not null
CREATE NONCLUSTERED INDEX [idx_tmortgagee_policy_history_sk] ON edw_core.tmortgagee (policy_history_sk)
