-- Rename columns in stage_majesco_transaction_data_feed table
-- policy_effective_date -> policy_eff_date
-- policy_expiration_date -> policy_exp_date

-- Rename policy_effective_date to policy_eff_date
EXEC sp_rename 'edw_stage.stage_majesco_transaction_data_feed.policy_effective_date', 'policy_eff_date', 'COLUMN';

-- Rename policy_expiration_date to policy_exp_date
EXEC sp_rename 'edw_stage.stage_majesco_transaction_data_feed.policy_expiration_date', 'policy_exp_date', 'COLUMN';
