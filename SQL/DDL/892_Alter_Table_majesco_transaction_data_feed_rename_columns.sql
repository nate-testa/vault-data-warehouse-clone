-- Rename columns in stage_majesco_transaction_data_feed table
-- policy_effective_date -> policy_eff_date
-- policy_expiration_date -> policy_exp_date

-- Rename policy_effective_date to policy_eff_date
IF EXISTS (SELECT 1 FROM sys.columns 
           WHERE object_id = OBJECT_ID('edw_stage.stage_majesco_transaction_data_feed') 
           AND name = 'policy_effective_date')
BEGIN
    EXEC sp_rename 'edw_stage.stage_majesco_transaction_data_feed.policy_effective_date', 'policy_eff_date', 'COLUMN'
END;

-- Rename policy_expiration_date to policy_exp_date
IF EXISTS (SELECT 1 FROM sys.columns 
           WHERE object_id = OBJECT_ID('edw_stage.stage_majesco_transaction_data_feed') 
           AND name = 'policy_expiration_date')
BEGIN
    EXEC sp_rename 'edw_stage.stage_majesco_transaction_data_feed.policy_expiration_date', 'policy_exp_date', 'COLUMN'
END;
